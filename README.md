# Build instructions for MapBox for iPad

 1. Download an [MBTiles](http://mbtiles.org/) tile set to bundle with the app, place it in <project>/tiles, and add it to the project as a resource.
 2. Update `bundled_tileset_md5sum.txt` as necessary.
 3. `git submodule update --init`
 4. Build & go!

## Requirements

 * Base SDK: iOS 5.1
 * Deployment Target: iOS 5.0

## License

Copyright (c) 2010-2012 Development Seed, Inc.
