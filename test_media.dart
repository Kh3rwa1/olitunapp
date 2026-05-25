import 'package:itun/shared/utils/media_type_resolver.dart';

void main() {
  print(
    "Image URL: " +
        MediaTypeResolver.resolve(
          'https://cloud.appwrite.io/v1/storage/buckets/lesson-images/files/123/view',
        ).toString(),
  );
  print(
    "Video URL: " +
        MediaTypeResolver.resolve(
          'https://cloud.appwrite.io/v1/storage/buckets/lesson-video/files/123/view',
        ).toString(),
  );
  print(
    "Media URL: " +
        MediaTypeResolver.resolve(
          'https://cloud.appwrite.io/v1/storage/buckets/lesson-media/files/123/view',
        ).toString(),
  );
  print(
    "Appwrite Video: " +
        MediaTypeResolver.resolve(
          'https://cloud.appwrite.io/v1/storage/buckets/videos/files/674251ba00109decf3dd/view?project=67406a4a001baef48e24',
        ).toString(),
  );
}
