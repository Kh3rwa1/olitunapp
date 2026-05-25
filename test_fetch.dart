import 'package:appwrite/appwrite.dart';

void main() async {
  Client client = Client()
      .setEndpoint('https://cloud.appwrite.io/v1')
      .setProject('67406a4a001baef48e24');
  Databases databases = Databases(client);

  try {
    final docs = await databases.listDocuments(
      databaseId: 'main_db',
      collectionId: 'lessons',
    );
    for (var doc in docs.documents) {
      final blocks = doc.data['blocks'];
      if (blocks != null && blocks.toString().contains('imageUrl')) {
        print('Lesson: ${doc.data['titleLatin']}');
        print(blocks);
      }
    }
  } catch (e) {
    print(e);
  }
}
