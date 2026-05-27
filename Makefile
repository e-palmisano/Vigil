VERSION ?= 1.0.0
SCHEME = Vigil
ARCHIVE_PATH = build/Vigil.xcarchive
EXPORT_PATH = build/export
DMG_PATH = build/Vigil-$(VERSION).dmg

.PHONY: build archive export dmg clean

build:
	xcodebuild -project Vigil.xcodeproj -scheme $(SCHEME) \
		-destination 'platform=macOS' \
		-configuration Release build

archive:
	xcodebuild archive \
		-project Vigil.xcodeproj \
		-scheme $(SCHEME) \
		-configuration Release \
		-archivePath $(ARCHIVE_PATH)

export: archive
	xcodebuild -exportArchive \
		-archivePath $(ARCHIVE_PATH) \
		-exportPath $(EXPORT_PATH) \
		-exportOptionsPlist ExportOptions.plist

dmg: export
	hdiutil create -volname Vigil -srcfolder $(EXPORT_PATH)/Vigil.app \
		-ov -format UDZO $(DMG_PATH)
	echo "DMG created: $(DMG_PATH)"
	shasum -a 256 $(DMG_PATH)

notarize: dmg
	xcrun notarytool submit $(DMG_PATH) \
		--apple-id "$(APPLE_ID)" \
		--team-id "$(TEAM_ID)" \
		--password "$(APP_PASSWORD)" \
		--wait
	xcrun stapler staple $(DMG_PATH)

clean:
	rm -rf build/
