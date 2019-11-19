TOOL_NAME = cdd-swift
VERSION = 0.1.0
BUILD_DIR = $(PWD)
CURRENT_PATH = $(PWD)
BUILD_PATH = .build/release/$(TOOL_NAME)
PREFIX = /usr/local
INSTALL_PATH = $(PREFIX)/bin/$(TOOL_NAME)

install-release:
	swift build --disable-sandbox -c release
	cp $(BUILD_PATH) ~/.cdd/bin/$(TOOL_NAME)

install:
	swift build
	cp .build/debug/$(TOOL_NAME) ~/.cdd/bin/$(TOOL_NAME)

build:
	swift build
	
run: build
	.build/debug/cdd-swift sync --dry-run ./Template

check: build
	.build/debug/cdd-swift check

alex: build
	.build/debug/cdd-swift generate

xcode:
	rm -rf cdd-swift.xcodeproj/
	swift package generate-xcodeproj

clean:
	swift package clean

test-cov:
	@swift package generate-xcodeproj
	@xcodebuild -scheme cdd-swift -derivedDataPath .build/xcode -enableCodeCoverage YES test
	@xcov --scheme cdd-swift --configuration Debug --derived_data_path .build/xcode --skip_slack --markdown_report
	@rm -rf .build/xcode
	@open xcov_report/index.html
