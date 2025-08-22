#!/usr/bin/env python3

import os
import sys
import json
import asyncio
import socket
import signal
import logging
import hashlib
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Set
from dataclasses import dataclass, asdict
from collections import deque

import yaml
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler, FileModifiedEvent, FileCreatedEvent, FileDeletedEvent
import diff_match_patch as dmp_module

from version import __version__, get_version_string, check_python_version

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('claude-code-watcher')


@dataclass
class FileChange:
    """Represents a file change event"""
    id: str
    file_path: str
    change_type: str  # CREATE, MODIFY, DELETE
    timestamp: str
    old_content: Optional[str] = None
    new_content: Optional[str] = None
    diff: Optional[Dict] = None
    
    def to_dict(self):
        return asdict(self)


class FileCache:
    """Cache file contents for diff calculation"""
    
    def __init__(self, max_size: int = 100):
        self.cache: Dict[str, str] = {}
        self.max_size = max_size
        self.access_order = deque(maxlen=max_size)
    
    def get(self, file_path: str) -> Optional[str]:
        if file_path in self.cache:
            self.access_order.remove(file_path)
            self.access_order.append(file_path)
            return self.cache[file_path]
        return None
    
    def set(self, file_path: str, content: str):
        if file_path not in self.cache and len(self.cache) >= self.max_size:
            oldest = self.access_order.popleft()
            del self.cache[oldest]
        
        self.cache[file_path] = content
        if file_path in self.access_order:
            self.access_order.remove(file_path)
        self.access_order.append(file_path)
    
    def remove(self, file_path: str):
        if file_path in self.cache:
            del self.cache[file_path]
            self.access_order.remove(file_path)


class DiffCalculator:
    """Calculate diffs between file versions"""
    
    def __init__(self):
        self.dmp = dmp_module.diff_match_patch()
        self.dmp.Diff_Timeout = 1.0  # 1 second timeout for diff calculation
    
    def calculate_diff(self, old_text: str, new_text: str) -> Dict:
        """Calculate diff between old and new text"""
        diffs = self.dmp.diff_main(old_text, new_text)
        self.dmp.diff_cleanupSemantic(diffs)
        
        hunks = []
        current_line = 1
        
        for op, text in diffs:
            lines = text.split('\n')
            if op == 0:  # EQUAL
                current_line += len(lines) - 1
            elif op == -1:  # DELETE
                hunks.append({
                    'type': 'delete',
                    'start_line': current_line,
                    'end_line': current_line + len(lines) - 1,
                    'text': text
                })
            elif op == 1:  # INSERT
                hunks.append({
                    'type': 'insert',
                    'start_line': current_line,
                    'text': text
                })
                current_line += len(lines) - 1
        
        return {
            'hunks': hunks,
            'additions': sum(1 for op, _ in diffs if op == 1),
            'deletions': sum(1 for op, _ in diffs if op == -1)
        }


class ClaudeCodeWatcher(FileSystemEventHandler):
    """Watches for file changes made by Claude Code"""
    
    def __init__(self, config: Dict):
        self.config = config
        self.cache = FileCache(max_size=config.get('cache_max_files', 100))
        self.diff_calc = DiffCalculator()
        self.change_queue = asyncio.Queue()
        self.ignored_patterns = set(config.get('ignore_patterns', []))
        self.watch_patterns = set(config.get('watch_patterns', ['*']))
        self.debounce_delay = config.get('debounce_delay', 0.1)
        self.pending_changes: Dict[str, asyncio.Task] = {}
        
        # Track Claude Code process
        self.claude_code_pid = self._find_claude_code_pid()
        
    def _find_claude_code_pid(self) -> Optional[int]:
        """Find Claude Code process ID"""
        try:
            import psutil
            for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
                if 'claude' in proc.info['name'].lower() or \
                   any('claude' in str(cmd).lower() for cmd in (proc.info['cmdline'] or [])):
                    return proc.info['pid']
        except:
            pass
        return None
    
    def _should_ignore(self, file_path: str) -> bool:
        """Check if file should be ignored"""
        path = Path(file_path)
        
        # Ignore hidden files and directories
        if any(part.startswith('.') for part in path.parts):
            return True
        
        # Check ignore patterns
        for pattern in self.ignored_patterns:
            if path.match(pattern):
                return True
        
        # Check if file matches watch patterns
        if self.watch_patterns and self.watch_patterns != {'*'}:
            if not any(path.match(pattern) for pattern in self.watch_patterns):
                return True
        
        return False
    
    async def _process_change(self, file_path: str, change_type: str):
        """Process a file change with debouncing"""
        # Wait for debounce delay
        await asyncio.sleep(self.debounce_delay)
        
        # Remove from pending changes
        if file_path in self.pending_changes:
            del self.pending_changes[file_path]
        
        try:
            # Read current file content
            new_content = None
            if change_type != 'DELETE' and os.path.exists(file_path):
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        new_content = f.read()
                except:
                    logger.warning(f"Could not read file: {file_path}")
                    return
            
            # Get cached content for diff
            old_content = self.cache.get(file_path)
            
            # Calculate diff if we have both versions
            diff = None
            if old_content and new_content and change_type == 'MODIFY':
                diff = self.diff_calc.calculate_diff(old_content, new_content)
            
            # Create change object
            change = FileChange(
                id=hashlib.md5(f"{file_path}{datetime.now()}".encode()).hexdigest()[:8],
                file_path=file_path,
                change_type=change_type,
                timestamp=datetime.now().isoformat(),
                old_content=old_content if len(old_content or '') < 10000 else None,
                new_content=new_content if len(new_content or '') < 10000 else None,
                diff=diff
            )
            
            # Update cache
            if new_content:
                self.cache.set(file_path, new_content)
            elif change_type == 'DELETE':
                self.cache.remove(file_path)
            
            # Queue the change
            await self.change_queue.put(change)
            logger.info(f"Queued change: {change_type} {file_path}")
            
        except Exception as e:
            logger.error(f"Error processing change for {file_path}: {e}")
    
    def on_modified(self, event):
        if not event.is_directory and not self._should_ignore(event.src_path):
            self._queue_change(event.src_path, 'MODIFY')
    
    def on_created(self, event):
        if not event.is_directory and not self._should_ignore(event.src_path):
            self._queue_change(event.src_path, 'CREATE')
    
    def on_deleted(self, event):
        if not event.is_directory and not self._should_ignore(event.src_path):
            self._queue_change(event.src_path, 'DELETE')
    
    def _queue_change(self, file_path: str, change_type: str):
        """Queue a change with debouncing"""
        # Cancel any pending change for this file
        if file_path in self.pending_changes:
            self.pending_changes[file_path].cancel()
        
        # Get or create event loop
        try:
            loop = asyncio.get_running_loop()
        except RuntimeError:
            # No loop running, need to schedule in main thread
            import threading
            if hasattr(self, '_main_loop'):
                loop = self._main_loop
            else:
                # Store change for later processing
                if not hasattr(self, '_queued_changes'):
                    self._queued_changes = []
                self._queued_changes.append((file_path, change_type))
                return
        
        # Schedule new change processing
        if loop:
            task = loop.create_task(self._process_change(file_path, change_type))
            self.pending_changes[file_path] = task


class IPCServer:
    """IPC server for communication with Neovim"""
    
    def __init__(self, socket_path: str, watcher: ClaudeCodeWatcher):
        self.socket_path = socket_path
        self.watcher = watcher
        self.clients: Set[asyncio.StreamWriter] = set()
        self.server = None
        
    async def start(self):
        """Start the IPC server"""
        # Remove existing socket file
        if os.path.exists(self.socket_path):
            os.unlink(self.socket_path)
        
        # Create socket directory if it doesn't exist
        os.makedirs(os.path.dirname(self.socket_path), exist_ok=True)
        
        # Start server
        self.server = await asyncio.start_unix_server(
            self.handle_client,
            path=self.socket_path
        )
        
        # Set socket permissions (owner only)
        os.chmod(self.socket_path, 0o600)
        
        logger.info(f"IPC server started on {self.socket_path}")
        
        # Start change broadcaster
        asyncio.create_task(self.broadcast_changes())
    
    async def handle_client(self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter):
        """Handle a new client connection"""
        logger.info("New client connected")
        self.clients.add(writer)
        
        try:
            # Send initial handshake
            await self.send_message(writer, {
                'type': 'HANDSHAKE',
                'version': '1.0.0',
                'timestamp': datetime.now().isoformat()
            })
            
            # Handle incoming messages
            while True:
                data = await reader.read(4096)
                if not data:
                    break
                
                try:
                    message = json.loads(data.decode())
                    await self.handle_message(message, writer)
                except json.JSONDecodeError:
                    logger.error(f"Invalid JSON received: {data}")
                except Exception as e:
                    logger.error(f"Error handling message: {e}")
        
        except asyncio.CancelledError:
            pass
        except Exception as e:
            logger.error(f"Client error: {e}")
        finally:
            self.clients.discard(writer)
            writer.close()
            await writer.wait_closed()
            logger.info("Client disconnected")
    
    async def handle_message(self, message: Dict, writer: asyncio.StreamWriter):
        """Handle incoming message from client"""
        msg_type = message.get('type')
        
        if msg_type == 'PING':
            await self.send_message(writer, {'type': 'PONG'})
        
        elif msg_type == 'GET_STATUS':
            await self.send_message(writer, {
                'type': 'STATUS',
                'watching': True,
                'queue_size': self.watcher.change_queue.qsize(),
                'cache_size': len(self.watcher.cache.cache)
            })
        
        elif msg_type == 'ACCEPT_CHANGE':
            change_id = message.get('change_id')
            logger.info(f"Change {change_id} accepted by client")
        
        elif msg_type == 'REJECT_CHANGE':
            change_id = message.get('change_id')
            logger.info(f"Change {change_id} rejected by client")
            # TODO: Implement rollback logic if needed
    
    async def send_message(self, writer: asyncio.StreamWriter, message: Dict):
        """Send a message to a client"""
        try:
            data = json.dumps(message).encode() + b'\n'
            writer.write(data)
            await writer.drain()
        except Exception as e:
            logger.error(f"Error sending message: {e}")
            self.clients.discard(writer)
    
    async def broadcast_changes(self):
        """Broadcast file changes to all connected clients"""
        while True:
            try:
                # Get change from queue
                change = await self.watcher.change_queue.get()
                
                # Broadcast to all clients
                message = {
                    'type': 'FILE_CHANGE',
                    'data': change.to_dict()
                }
                
                # Send to all connected clients
                disconnected = []
                for client in self.clients:
                    try:
                        await self.send_message(client, message)
                    except:
                        disconnected.append(client)
                
                # Remove disconnected clients
                for client in disconnected:
                    self.clients.discard(client)
                
            except Exception as e:
                logger.error(f"Error broadcasting changes: {e}")
                await asyncio.sleep(1)


async def main():
    """Main entry point"""
    # Check Python version
    if not check_python_version():
        from version import MIN_PYTHON_VERSION
        logger.error(f"Python {'.'.join(map(str, MIN_PYTHON_VERSION))} or higher is required")
        sys.exit(1)
    
    # Show version info
    logger.info(get_version_string())
    
    # Load configuration
    config_path = Path(__file__).parent / 'config.yaml'
    if config_path.exists():
        with open(config_path) as f:
            config = yaml.safe_load(f)
    else:
        config = {
            'watch_paths': [os.getcwd()],
            'socket_path': '/tmp/claude-code-nvim.sock',
            'ignore_patterns': [
                '*.pyc', '__pycache__', 'node_modules',
                '.git', '.svn', '.hg', '*.swp', '*.swo'
            ],
            'cache_max_files': 100,
            'debounce_delay': 0.1
        }
    
    # Create watcher
    watcher = ClaudeCodeWatcher(config)
    
    # Store the main event loop in watcher for cross-thread access
    watcher._main_loop = asyncio.get_running_loop()
    
    # Set up file system observer
    observer = Observer()
    for path in config['watch_paths']:
        observer.schedule(watcher, path, recursive=True)
        logger.info(f"Watching: {path}")
    
    # Start observer
    observer.start()
    
    # Create and start IPC server
    ipc_server = IPCServer(config['socket_path'], watcher)
    await ipc_server.start()
    
    # Handle shutdown
    def signal_handler(sig, frame):
        logger.info("Shutting down...")
        observer.stop()
        if os.path.exists(config['socket_path']):
            os.unlink(config['socket_path'])
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        # Keep running
        await asyncio.Event().wait()
    finally:
        observer.stop()
        observer.join()


if __name__ == '__main__':
    asyncio.run(main())