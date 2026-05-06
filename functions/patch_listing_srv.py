import re

with open('/home/sanma613/UProjects/CowBnB/frontend/lib/services/listing_service.dart', 'r') as f:
    text = f.read()

text = text.replace('}\n}', "}\n\n  Future<void> recordView(String listingId) async {\n    final user = _auth.currentUser;\n    final idToken = user != null ? await user.getIdToken() : null;\n    try {\n      await apiClient.postJson(\n        '/api/listings/$listingId/view',\n        idToken: idToken ?? '',\n        body: {},\n      );\n    } catch (e) {\n      debugPrint('Error recording view: $e');\n    }\n  }\n}")

with open('/home/sanma613/UProjects/CowBnB/frontend/lib/services/listing_service.dart', 'w') as f:
    f.write(text)
