# MapBoxiPadDemo

This is our testbed for mapping work on the iPad. Currently the app is a moving target showcasing whatever we want to do with mapping.

## Notes

* You will need to supply an .mbtiles file since they're so large. Currently it's best to use a full-globe tile set like World Light. Just drag the file into the project under Resources and it should copy in.

* Note that the builds, both Debug and Release, will make a copy of the .mbtiles file, so working copies can get quite large. So far, I've added `build` and `../stuff to not backup` (the source of my .mbtiles file) to Time Machine excludes to help with this.