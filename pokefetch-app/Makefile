BUNDLE    = PokefetchApp
BINARY    = .build/release/$(BUNDLE)
APP_DIR   = build/$(BUNDLE).app
CONTENTS  = $(APP_DIR)/Contents
MACOS_DIR = $(CONTENTS)/MacOS
RESOURCES_DIR = $(CONTENTS)/Resources

.PHONY: all build app run clean

# Default: build the .app bundle and open it
all: app

## Compile the Swift sources (release)
build:
	swift build -c release

## Assemble the .app bundle from the compiled binary
app: build
	@echo "📦 Ensamblando $(BUNDLE).app..."
	@mkdir -p $(MACOS_DIR)
	@mkdir -p $(RESOURCES_DIR)
	@cp $(BINARY) $(MACOS_DIR)/$(BUNDLE)
	@cp Info.plist $(CONTENTS)/Info.plist
	@if [ -f "icon.png" ]; then \
		echo "🎨 Generando icono..."; \
		mkdir -p AppIcon.iconset; \
		sips -z 16 16     icon.png --out AppIcon.iconset/icon_16x16.png > /dev/null; \
		sips -z 32 32     icon.png --out AppIcon.iconset/icon_16x16@2x.png > /dev/null; \
		sips -z 32 32     icon.png --out AppIcon.iconset/icon_32x32.png > /dev/null; \
		sips -z 64 64     icon.png --out AppIcon.iconset/icon_32x32@2x.png > /dev/null; \
		sips -z 128 128   icon.png --out AppIcon.iconset/icon_128x128.png > /dev/null; \
		sips -z 256 256   icon.png --out AppIcon.iconset/icon_128x128@2x.png > /dev/null; \
		sips -z 256 256   icon.png --out AppIcon.iconset/icon_256x256.png > /dev/null; \
		sips -z 512 512   icon.png --out AppIcon.iconset/icon_256x256@2x.png > /dev/null; \
		sips -z 512 512   icon.png --out AppIcon.iconset/icon_512x512.png > /dev/null; \
		sips -z 1024 1024 icon.png --out AppIcon.iconset/icon_512x512@2x.png > /dev/null; \
		iconutil -c icns AppIcon.iconset -o $(RESOURCES_DIR)/AppIcon.icns; \
		rm -R AppIcon.iconset; \
	fi
	@echo "✅ Listo: $(APP_DIR)"

## Open the app (builds first if needed)
run: app
	@open $(APP_DIR)

## Remove build artifacts
clean:
	swift package clean
	rm -rf build/
