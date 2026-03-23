const admin = require("firebase-admin");
const fs = require("fs");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const raw = JSON.parse(
  fs.readFileSync("C:/Users/Admin/.gemini/antigravity/scratch/smartqueue_user/smartqueue_firestore_full_seed.json", "utf8")
);

// convert object → array
function normalize(data) {
  if (!data) return [];
  if (Array.isArray(data)) return data;
  return Object.values(data);
}

const sectors = normalize(raw.sectors);
const branches = normalize(raw.branches);
const services = normalize(raw.services);
const counters = normalize(raw.counters);
const admins = normalize(raw.admins);
const queues = normalize(raw.queues);

async function upload(collection, items) {

  console.log(`Uploading ${collection} (${items.length})`);

  for (const item of items) {

    const id = item.id || item.counterId || item.branchId;

    await db.collection(collection).doc(id).set(item);

  }

  console.log(`✅ ${collection} done`);

}

async function run() {

  await upload("sectors", sectors);
  await upload("branches", branches);
  await upload("services", services);
  await upload("counters", counters);
  await upload("admins", admins);
  await upload("queues", queues);

  console.log("🔥 ALL DATA UPLOADED");

}

run();