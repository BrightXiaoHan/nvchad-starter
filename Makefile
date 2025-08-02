.PHONY: format check install-stylua

# Format all Lua files using stylua
format:
	@echo "Formatting Lua files..."
	@stylua lua/ init.lua

# Check formatting without making changes
check:
	@echo "Checking Lua formatting..."
	@stylua --check lua/ init.lua

# Help target
help:
	@echo "Available targets:"
	@echo "  format       - Format all Lua files"
	@echo "  check        - Check formatting without changes"
	@echo "  help         - Show this help message"