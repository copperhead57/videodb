#!/bin/bash

# Remove XAMPP's poisoned library path
unset LD_LIBRARY_PATH

# Run system node with clean environment
exec /usr/bin/node "$@"
