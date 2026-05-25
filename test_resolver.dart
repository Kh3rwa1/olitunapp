import 'package:itun/shared/utils/media_type_resolver.dart';

void main() {
  final url =
      'https://cloud.appwrite.io/v1/storage/buckets/lesson-media/files/674088a2002cd401f810/view?project=67406a4a001baef48e24';
  print(MediaTypeResolver.resolve(url));
  print(MediaTypeResolver.isRenderableHero(url));
}
