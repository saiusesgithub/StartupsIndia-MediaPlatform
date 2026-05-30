class AppConfig {
  const AppConfig._();

  static const environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'prod',
  );

  static const cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'dmrp1d1tv',
  );

  static const cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'startups india upload preset',
  );
}
