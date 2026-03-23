const admin = require('firebase-admin');

// 1. INITIALIZE FIREBASE ADMIN
// Make sure you have the serviceAccountKey.json in the same directory
// or provide the path to it.
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function mapServicesToCounters() {
  console.log('🚀 Starting Counter Service Mapping...');

  try {
    // 2. READ ALL SERVICES
    const servicesSnapshot = await db.collection('services').get();
    const services = [];
    servicesSnapshot.forEach(doc => {
      services.push({ id: doc.id, ...doc.data() });
    });
    console.log(`📦 Fetched ${services.length} services.`);

    // 3. GROUP SERVICES BY branchId
    const servicesByBranch = {};
    services.forEach(service => {
      const branchId = service.branchId;
      if (!servicesByBranch[branchId]) {
        servicesByBranch[branchId] = [];
      }
      servicesByBranch[branchId].push(service.id);
    });

    // 4. READ ALL COUNTERS
    const countersSnapshot = await db.collection('counters').get();
    const countersByBranch = {};
    countersSnapshot.forEach(doc => {
      const data = doc.data();
      const branchId = data.branchId;
      if (!countersByBranch[branchId]) {
        countersByBranch[branchId] = [];
      }
      countersByBranch[branchId].push({ id: doc.id, name: data.name });
    });
    console.log(`🏢 Fetched counters for ${Object.keys(countersByBranch).length} branches.`);

    // 5. PROCESS MAPPING
    const batch = db.batch();
    let updateCount = 0;

    for (const branchId in servicesByBranch) {
      const branchServices = servicesByBranch[branchId];
      const branchCounters = countersByBranch[branchId];

      if (!branchCounters || branchCounters.length < 2) {
        console.warn(`⚠️ Branch ${branchId} does not have at least 2 counters. Skipping mapping.`);
        continue;
      }

      // Sort services to ensure consistent splitting if names were available, 
      // but here we use IDs as requested.
      branchServices.sort();

      // Split services into two halves
      const midPoint = Math.ceil(branchServices.length / 2);
      const firstHalf = branchServices.slice(0, midPoint);
      const secondHalf = branchServices.slice(midPoint);

      // We expect exactly 2 counters per branch requirements
      // Counter 1 (usually named with '1' or the first one found)
      // We'll check names for "1" and "2" just in case, otherwise fallback to order.
      let counter1 = branchCounters.find(c => c.name.includes('1')) || branchCounters[0];
      let counter2 = branchCounters.find(c => c.name.includes('2')) || branchCounters[1];

      // Update Counter 1
      const c1Ref = db.collection('counters').doc(counter1.id);
      batch.update(c1Ref, { serviceIds: firstHalf });
      console.log(`✅ Assigned ${firstHalf.length} services to counter: ${counter1.name} (${branchId})`);

      // Update Counter 2
      const c2Ref = db.collection('counters').doc(counter2.id);
      batch.update(c2Ref, { serviceIds: secondHalf });
      console.log(`✅ Assigned ${secondHalf.length} services to counter: ${counter2.name} (${branchId})`);

      updateCount += 2;
    }

    // 6. COMMIT BATCH
    if (updateCount > 0) {
      await batch.commit();
      console.log(`\n🎉 SUCCESS: Updated ${updateCount} counters mapping.`);
    } else {
      console.log('\n✨ No updates needed.');
    }

  } catch (error) {
    console.error('❌ Error during mapping:', error);
  }
}

mapServicesToCounters();
