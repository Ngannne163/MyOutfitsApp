const functions = require('firebase-functions/v1');
const algoliasearch = require('algoliasearch');
const admin = require('firebase-admin');

// --- THÔNG TIN ALGOLIA CỨNG (SỬ DỤNG ADMIN KEY) ---
const ALGOLIA_APP_ID_FIXED = "RP42OZFM22";
const ALGOLIA_ADMIN_KEY_FIXED = "af10e1aa2d6d0ab8a2d99976e7f18220";
// ----------------------------------------------------

// 1. Khởi tạo Admin SDK (Chỉ chạy một lần)
admin.initializeApp();
const db = admin.firestore();

// 2. Khởi tạo Algolia Client VÀ Indexes (Chỉ chạy một lần)
const algoliaClient = algoliasearch(ALGOLIA_APP_ID_FIXED, ALGOLIA_ADMIN_KEY_FIXED);
const POSTS_INDEX = algoliaClient.initIndex('posts_index');
const OUTFITS_INDEX = algoliaClient.initIndex('outfits_index');

console.log("Global Algolia services and Firebase initialized successfully.");

// --- 1. Đồng bộ hóa POSTS (V1) ---
// BẮT BUỘC THÊM .runWith() để ghi đè cache lỗi
exports.syncPostToAlgoliaV1 = functions.runWith({
    memory: '256MB', // Cấu hình Gen 1 tường minh
    timeoutSeconds: 30 // Giới hạn thời gian 30 giây mặc định
  }).firestore
  .document("posts/{postId}")
  .onWrite(async (change, context) => {

    // Đảm bảo truy cập params trực tiếp từ context
    const postId = context.params.postId;
    const postData = change.after.exists ? change.after.data() : null;

    console.log(`--- Sync Triggered (V1 Final) for Post ID: ${postId}. Exists: ${change.after.exists} ---`);

    if (!postData) {
      console.log(`Attempting to delete post ${postId} from Algolia.`);

      try {
        await POSTS_INDEX.deleteObject(postId);
        console.log(`SUCCESS: Post ${postId} deleted from Algolia.`);
      } catch (error) {
        console.error(`ERROR: Failed to delete post ${postId} from Algolia.`, error.message);
      }
      return;
    }

    console.log(`Post Data: ${JSON.stringify({ description: postData.description, tags: postData.allTags })}`);

    const algoliaObject = {
      objectID: postId,
      description: postData.description || '',
      allTags: postData.allTags || [],
      likesCount: postData.likesCount || 0,
      imageURLs: postData.imageURLs || [],
      timestamp: postData.timestamp ? postData.timestamp.toDate().getTime() : Date.now(),
    };

    try {
      await POSTS_INDEX.saveObject(algoliaObject);
      console.log(`SUCCESS: Post ${postId} added/updated in Algolia.`);
    } catch (error) {
      console.error(`CRITICAL ERROR: Failed to save post ${postId} to Algolia.`, error.message);
    }
  });


// --- 2. Đồng bộ hóa OUTFITS (HTTP Callable V1) ---
exports.syncAllOutfitsV1 = functions.runWith({
    memory: '1GB',
    timeoutSeconds: 300, // Cấu hình Gen 1 tường minh
}).https.onCall(async (data, context) => {
  const genders = ['man', 'woman'];
  const allOutfitObjects = [];

  for (const gender of genders) {
    const snapshot = await db.collection('outfits').doc(gender).collection('1').get();

    snapshot.forEach(doc => {
      const outfit = doc.data();

      const algoliaObject = {
        objectID: `${gender}_${doc.id}`,
        categories: outfit.categories || [],
        places: outfit.places || [],
        season: outfit.season || [],
        type: outfit.type || [],
        gender: gender,
        imageURL: outfit.imageURL || null,
      };
      allOutfitObjects.push(algoliaObject);
    });
  }

  if (allOutfitObjects.length === 0) {
    console.log("No outfits found to sync.");
    return { success: true, count: 0, message: "Không tìm thấy outfits nào để đồng bộ." };
  }

  try {
    const result = await OUTFITS_INDEX.saveObjects(allOutfitObjects);
    console.log(`Successfully indexed ${allOutfitObjects.length} outfits. Task ID: ${result.taskID}`);
    return {
      success: true,
      count: allOutfitObjects.length,
      message: `Đồng bộ hóa thành công ${allOutfitObjects.length} outfits.`
    };
  } catch (error) {
    console.error("CRITICAL: Algolia indexing failed (OUTFITS):", error.message);
    throw new functions.https.HttpsError('internal', `Lỗi khi đồng bộ hóa Algolia: ${error.message}`, error);
  }
});

exports.syncAllPostsV1 = functions.runWith({
    memory: '1GB',
    timeoutSeconds: 300,
}).https.onCall(async (data, context) => {
  const allPostObjects = [];
  try {
    const postsSnapshot = await db.collection('posts').get();

    postsSnapshot.forEach(doc => {
      const postData = doc.data();

      const algoliaObject = {
        objectID: doc.id,
        description: postData.description || '',
        allTags: postData.allTags || [],
        likesCount: postData.likesCount || 0,
        imageURLs: postData.imageURLs || [],
        timestamp: postData.timestamp ? postData.timestamp.toDate().getTime() : Date.now(),
      };
      allPostObjects.push(algoliaObject);
    });

    if (allPostObjects.length === 0) {
      console.log("No posts found to sync.");
      return { success: true, count: 0, message: "Không tìm thấy posts nào để đồng bộ." };
    }

    const result = await POSTS_INDEX.saveObjects(allPostObjects);
    console.log(`Successfully indexed ${allPostObjects.length} posts. Task ID: ${result.taskID}`);

    return {
      success: true,
      count: allPostObjects.length,
      message: `Đồng bộ hóa thành công ${allPostObjects.length} posts.`
    };
  } catch (error) {
    console.error("CRITICAL: Algolia indexing failed (POSTS):", error.message);
    throw new functions.https.HttpsError('internal', `Lỗi khi đồng bộ hóa Algolia (POSTS): ${error.message}`, error);
  }
});