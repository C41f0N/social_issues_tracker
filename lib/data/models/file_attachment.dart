class FileAttachment {
  String id;
  String name; // base file name without extension (display)
  String extension; // e.g. pdf, jpg, mp4
  String uploadLink; // remote URL or storage reference

  FileAttachment({
    required this.id,
    required this.name,
    required this.extension,
    required this.uploadLink,
  });
}
