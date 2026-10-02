/// What importing a backup added to the app.
///
/// [works] and [visits] count only the ones that were not here already —
/// importing the same backup twice adds nothing the second time.
/// [missingPictures] are pictures of the new visits whose files are not on
/// this device: a backup holds the rows, not the image files, so those are
/// left out rather than drawn as broken.
typedef BackupImport = ({int works, int visits, int missingPictures});
