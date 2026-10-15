#!/usr/bin/env node
import fs from 'fs';
import path from 'path';

const ARB_DIR = path.join('lib', 'l10n', 'arb');
const LOCALES = ['en', 'sat', 'hi', 'bn', 'or'];

const NEW_KEYS = {
  "failureGeneric": {
    "en": "Something went wrong. Please try again.",
    "sat": "ᱠᱷᱚᱱ ᱠᱟᱛᱟᱨᱤ ᱠᱮᱭᱟᱱ. ᱠᱷᱚᱱ ᱥᱦᱟᱯᱟᱨᱠᱟᱨ ᱢᱮ.",
    "hi": "कुछ गलत हो गया। कृपया पुनः प्रयास करें।",
    "bn": "কিছু ভুল হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।",
    "or": "କିଛି ଭୁଲ୍ ହୋଇଗଲା। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।"
  },
  "failureNoInternet": {
    "en": "No internet connection. Check your network and retry.",
    "sat": "ᱤᱱᱴᱟᱨᱩᱱᱛ ᱠᱚᱱᱠᱟᱠᱠᱟᱢ ᱠᱷᱟᱲᱟᱢᱟᱱ. ᱠᱟᱱᱠᱟᱠ ᱧᱮᱞ ᱠᱟᱨᱤ ᱥᱦᱟᱯᱟᱨᱠᱟᱨ ᱢᱮ.",
    "hi": "इंटरनेट कनेक्शन नहीं है। अपना नेटवर्क जाँचें और पुनः प्रयास करें।",
    "bn": "ইন্টারনেট সংযোগ নেই। আপনার নেটওয়ার্ক পরীক্ষা করুন এবং আবার চেষ্টা করুন।",
    "or": "ଇଣ୍ଟରନେଟ୍ ସଂଯୋଗ ନାହିଁ। ଆପଣଙ୍କ ନେଟୱର୍କ ଯାଞ୍ଚ କରନ୍ତୁ ଏବଂ ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।"
  },
  "failureSignInAgain": {
    "en": "Please sign in again to continue.",
    "sat": "ᱵᱟᱦᱟᱨᱟᱢ ᱠᱷᱚᱱ ᱥᱦᱟᱯᱟᱨᱠᱟᱨ ᱥᱟᱭᱤᱱ ᱟᱷᱟᱰᱢᱟᱢᱮ.",
    "hi": "जारी रखने के लिए कृपया फिर से साइन इन करें।",
    "bn": "চালিয়ে যেতে অনুগ্রহ করে আবার সাইন ইন করুন।",
    "or": "ଜାରି ରଖିବା ପାଇଁ ଦୟାକରି ପୁଣି ସାଇନ୍ ଇନ୍ କରନ୍ତୁ।"
  },
  "failureNotFound": {
    "en": "This content was not found.",
    "sat": "ᱤᱱ ᱠᱚᱱᱛᱟᱱᱛ ᱵᱟᱦᱟᱨᱟᱢ ᱠᱟᱱᱟᱢᱟᱱ.",
    "hi": "यह सामग्री नहीं मिली।",
    "bn": "এই কন্টেন্ট পাওয়া যায়নি।",
    "or": "ଏହି ସାମଗ୍ରୀ ମିଳିଲା ନାହିଁ।"
  },
  "failureTracingRequired": {
    "en": "Tracing data is required for letters and numbers.",
    "sat": "ᱠᱟᱛᱟᱨᱤ ᱟᱨ ᱜᱟᱲᱩᱠᱚᱢ ᱠᱷᱚᱱ ᱛᱨᱤᱠᱤᱝ ᱠᱟᱛᱟᱨᱤ ᱠᱮᱢᱟᱱ.",
    "hi": "अक्षरों और संख्याओं के लिए ट्रेसिंग डेटा आवश्यक है।",
    "bn": "অক্ষর ও সংখ্যার জন্য হাতের লেখা তথ্য প্রয়োজন।",
    "or": "ଅକ୍ଷର ଏବଂ ସଂଖ୍ୟା ପାଇଁ ଟ୍ରେସିଂ୍ ତଥ୍ୟ ଆବଶ୍ୟକ।"
  },
  "contentCouldNotBeLoaded": {
    "en": "Content could not be loaded. Please try again.",
    "sat": "ᱠᱚᱱᱛᱟᱱᱛ ᱵᱟᱦᱟᱨᱟᱢ ᱠᱟᱱᱟᱢᱟᱱ. ᱠᱷᱚᱱ ᱥᱦᱟᱯᱟᱨᱠᱟᱨ ᱢᱮ.",
    "hi": "सामग्री लोड नहीं हो सकी। कृपया पुनः प्रयास करें।",
    "bn": "কন্টেন্ট লোড করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।",
    "or": "ସାମଗ୍ରୀ ଲୋଡ୍ କରିପାରିଲା ନାହିଁ। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।"
  },
  "couldNotClearDownloads": {
    "en": "Could not clear downloads",
    "sat": "ᱵᱟᱦᱟᱨᱟᱢ ᱫᱩᱱᱠᱟᱨᱟᱜᱟᱢ ᱥᱟ᱑ᱟᱨᱟᱢ ᱠᱟᱱᱟᱢᱟᱱ",
    "hi": "डाउनलोड साफ़ नहीं किए जा सके",
    "bn": "ডাউনলোড পরিষ্কার করা যায়নি",
    "or": "ଡାଉନଲୋଡ୍ ସଫା କରିପାରିଲା ନାହିଁ"
  },
  "continueWithEmail": {
    "en": "Continue with Email",
    "sat": "ᱤᱢᱮᱞ ᱠᱷᱚᱱ ᱵᱟᱦᱟᱨᱟᱢᱮ",
    "hi": "ईमेल से जारी रखें",
    "bn": "ইমেল দিয়ে চালিয়ে যান",
    "or": "ଇମେଲ୍ ଦ୍ୱାରା ଜାରି ରଖନ୍ତୁ"
  },
  "exploreAsGuest": {
    "en": "Explore as Guest",
    "sat": "ᱥᱤᱛᱟᱨ ᱠᱷᱚᱱ ᱫᱮᱜᱟᱭᱟᱢᱮ",
    "hi": "अतिथि के रूप में देखें",
    "bn": "অতিথি হিসেবে দেখুন",
    "or": "ଅତିଥି ଭାବରେ ଦେଖନ୍ତୁ"
  },
  "continueWithGoogle": {
    "en": "Continue with Google",
    "sat": "ᱜᱩᱜᱩᱞ ᱠᱷᱚᱱ ᱵᱟᱦᱟᱨᱟᱢᱮ",
    "hi": "गूगल से जारी रखें",
    "bn": "গুগল দিয়ে চালিয়ে যান",
    "or": "ଗୁଗଲ୍ ଦ୍ୱାରା ଜାରି ରଖନ୍ତୁ"
  },
  "guestSessionFailed": {
    "en": "Could not start a guest session. Please try again.",
    "sat": "ᱥᱤᱛᱟᱨ ᱥᱩᱠᱤᱥ ᱜᱟᱭᱟᱢ ᱠᱟᱱᱟᱢᱟᱱ. ᱠᱷᱚᱱ ᱥᱦᱟᱯᱟᱨᱠᱟᱨ ᱢᱮ.",
    "hi": "अतिथि सत्र शुरू नहीं हो सका। कृपया पुनः प्रयास करें।",
    "bn": "গেস্ট সেশন শুরু করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।",
    "or": "ଅତିଥି ସେସନ୍ ଆରମ୍ଭ କରିପାରିଲା ନାହିଁ। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।"
  },
  "couldNotOpenShareSheet": {
    "en": "Could not open share sheet",
    "sat": "ᱥᱟᱨᱮᱠ ᱥᱟᱦᱟᱨ ᱫᱟᱣᱟᱹᱨᱟᱢ ᱠᱟᱱᱟᱢᱟᱱ",
    "hi": "शेयर शीट नहीं खुल सकी",
    "bn": "শেয়ার শীট খোলা যায়নি",
    "or": "ଶେୟାର୍ ସିଟ୍ ଖୋଲିପାରିଲା ନାହିଁ"
  },
  "progressLoadFailed": {
    "en": "Your saved progress is still safe. Try refreshing this view.",
    "sat": "ᱠᱟᱛᱷᱟᱨᱤ ᱯᱨᱳᱜᱨᱮᱥ ᱠᱩᱞᱟᱹᱣ ᱠᱟᱛᱷᱟᱨᱤ ᱠᱟᱱᱟᱱ. ᱤᱱ ᱛᱟᱦᱲᱟᱹ ᱱᱟᱹᱜᱩᱟᱱ ᱥᱦᱟᱯᱟᱨᱠᱟᱨ ᱢᱮ.",
    "hi": "आपकी सहेजी गई प्रगति सुरक्षित है। इस व्यू को रिफ्रेश करके देखें।",
    "bn": "আপনার সংরক্ষিত অগ্রগতি এখনও নিরাপদ। এই ভিউ রিফ্রেশ করে দেখুন।",
    "or": "ଆପଣଙ୍କ ସଂରକ୍ଷିତ ପ୍ରଗତି ଏଯାଏଁ ସୁରକ୍ଷିତ। ଏହି ଭ୍ୟୁ ରିଫ୍ରେସ୍ କରି ଦେଖନ୍ତୁ।"
  },
  "googleSignInFailed": {
    "en": "Google sign-in failed. Please try again.",
    "sat": "ᱜᱩᱜᱩᱞ ᱥᱟᱭᱤᱱ ᱷᱟᱰ ᱫᱟᱲᱟᱭᱟᱱ. ᱠᱷᱚᱱ ᱥᱦᱟᱯᱟᱨᱠᱟᱨ ᱢᱮ.",
    "hi": "गूगल साइन इन विफल रहा। कृपया पुनः प्रयास करें।",
    "bn": "গুগল সাইন ইন ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।",
    "or": "ଗୁଗଲ୍ ସାଇନ୍ ଇନ୍ ବିଫଳ ହେଲା। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।"
  },
  "traceGuidelines": {
    "en": "Trace the character guidelines accurately",
    "sat": "ᱠᱟᱛᱟᱨᱤ ᱜᱟᱤᱞᱟᱤᱱᱰᱟᱭᱩᱠᱚᱨ ᱠᱩᱨᱩᱢᱟᱭᱟᱢᱩ ᱱᱤᱱᱟᱢ ᱟᱷᱟᱰᱢᱟᱢᱮ",
    "hi": "अक्षर के दिशा-निर्देशों को सही से ट्रेस करें",
    "bn": "অক্ষরের নির্দেশিকা সঠিকভাবে ট্রেস করুন",
    "or": "ଅକ୍ଷରର ନିର୍ଦ୍ଦେଶିକା ସଠିକ୍ ଭାବରେ ଟ୍ରେସ୍ କରନ୍ତୁ"
  },
  "showExample": {
    "en": "Show example",
    "sat": "ᱯᱟᱨᱦᱟᱨ ᱠᱩᱨᱩᱢᱟᱭᱟᱢᱩ ᱢᱮ",
    "hi": "उदाहरण दिखाएँ",
    "bn": "উদাহরণ দেখান",
    "or": "ଉଦାହରଣ ଦେଖାନ୍ତୁ"
  },
  "shareMessageCopied": {
    "en": "Share message copied to clipboard!",
    "sat": "ᱥᱟᱨᱮᱠ ᱡᱟᱦᱟᱸ ᱠᱞᱤᱯᱜᱷᱟᱯ ᱠᱷᱚᱱ ᱠᱩᱯᱷᱟᱢᱟᱱ!",
    "hi": "शेयर संदेश क्लिपबोर्ड पर कॉपी हो गया!",
    "bn": "শেয়ার বার্তা ক্লিপবোর্ডে কপি হয়েছে!",
    "or": "ଶେୟାର୍ ବାର୍ତ୍ତା କ୍ଲିପବୋର୍ଡକୁ କପି ହେଲା!"
  },
  "shareMilestoneTitle": {
    "en": "Share Your Milestone",
    "sat": "ᱠᱟᱛᱷᱟᱨᱤ ᱢᱟᱲᱟᱥᱛᱟᱣ ᱦᱟᱹᱴᱤᱧ ᱢᱮ",
    "hi": "अपनी उपलब्धि साझा करें",
    "bn": "আপনার অর্জন শেয়ার করুন",
    "or": "ଆପଣଙ୍କ ଅର୍ଜନ ସେୟାର୍ କରନ୍ତୁ"
  },
  "shareMilestoneSubtitle": {
    "en": "Inspire others to learn Santali & Ol Chiki",
    "sat": "ᱥᱟᱱᱛᱟᱲᱤ ᱟᱨ ᱠᱚᱨᱤ ᱠᱤᱠᱤ ᱥᱤᱠᱨᱤᱯᱛ ᱞᱟᱹᱜᱤᱫ ᱠᱷᱚᱱ ᱡᱟᱛᱩᱨ ᱛᱮᱜᱮ ᱦᱟᱹᱴᱤᱧ ᱢᱮ",
    "hi": "संताली और ओल चिकी सीखने के लिए दूसरों को प्रेरित करें",
    "bn": "সানতালি ও ওল চিকি শেখার জন্য অন্যদের অনুপ্রাণিত করুন",
    "or": "ସାନ୍ତାଳି ଏବଂ ଓଲ୍ ଚିକି ଶିଖିବା ପାଇଁ ଅନ୍ୟମାନଙ୍କୁ ପ୍ରେରଣା ଦିଅନ୍ତୁ"
  },
  "copyTextSummary": {
    "en": "Copy Text Summary",
    "sat": "ᱛᱮᱠᱥᱛ ᱜᱟᱲᱟᱭ ᱠᱚᱯᱤ ᱢᱮ",
    "hi": "टेक्स्ट सारांश कॉपी करें",
    "bn": "লেখার সারাংশ কপি করুন",
    "or": "ଲେଖ ସାରାଂଶ କପି କରନ୍ତୁ"
  },
  "couldNotLoadLessons": {
    "en": "Could not load lessons",
    "sat": "ᱯᱟᱴ ᱵᱟᱦᱟᱨᱟᱢ ᱠᱟᱱᱟᱢᱟᱱ",
    "hi": "पाठ लोड नहीं हो सके",
    "bn": "পাঠ লোড করা যায়নি",
    "or": "ପାଠ ଲୋଡ୍ କରିପାରିଲା ନାହିଁ"
  },
  "learningPathNotFound": {
    "en": "Learning path not found",
    "sat": "ᱡᱟᱦᱟᱸᱞᱟᱣ ᱫᱮᱜᱟᱢ ᱠᱟᱛᱷᱟᱨᱤ ᱵᱟᱦᱟᱨᱟᱢ ᱠᱟᱱᱟᱢᱟᱱ",
    "hi": "शिक्षण पथ नहीं मिला",
    "bn": "শেখার পথ পাওয়া যায়নি",
    "or": "ଶିକ୍ଷଣ ପଥ ମିଳିଲା ନାହିଁ"
  },
  "noLearningPathsYet": {
    "en": "No learning paths yet",
    "sat": "ᱠᱷᱚᱱ ᱡᱟᱦᱟᱸᱞᱟᱣ ᱫᱮᱜᱟᱢ ᱵᱟᱦᱟᱨᱟᱱ",
    "hi": "अभी कोई शिक्षण पथ नहीं है",
    "bn": "এখনও কোনো শেখার পথ নেই",
    "or": "ଏବେ କୌଣସି ଶିକ୍ଷଣ ପଥ ନାହିଁ"
  },
  "signOut": {
    "en": "Sign Out",
    "sat": "ᱥᱟᱭᱤᱱ ᱷᱟᱰᱮ",
    "hi": "साइन आउट",
    "bn": "সাইন আউট",
    "or": "ସାଇନ୍ ଆଉଟ୍"
  },
  "delete": {
    "en": "Delete",
    "sat": "ᱣᱤᱠᱟᱨ",
    "hi": "हटाएँ",
    "bn": "মুছুন",
    "or": "ଲୁପ୍ତ କରନ୍ତୁ"
  },
  "finishLesson": {
    "en": "Finish Lesson",
    "sat": "ᱯᱟᱴ ᱡᱟᱦᱟᱸᱭ",
    "hi": "पाठ पूरा करें",
    "bn": "পাঠ শেষ করুন",
    "or": "ପାଠ ସମାପ୍ତ କରନ୍ତୁ"
  }
};

function main() {
  for (const loc of LOCALES) {
    const file = path.join(ARB_DIR, `app_${loc}.arb`);
    const data = JSON.parse(fs.readFileSync(file, 'utf8'));
    let added = 0;
    for (const [key, entry] of Object.entries(NEW_KEYS)) {
      if (key in data) continue;
      data[key] = entry[loc];
      added += 1;
    }
    // Rebuild preserving @@locale first, then original order, then new keys
    const ordered = {};
    if (data['@@locale']) ordered['@@locale'] = data['@@locale'];
    // Keep original key order from file on disk for non-new keys
    const orig = JSON.parse(fs.readFileSync(file, 'utf8'));
    for (const k of Object.keys(orig)) {
      if (k in data) ordered[k] = data[k];
    }
    for (const k of Object.keys(data)) {
      if (!(k in ordered)) ordered[k] = data[k];
    }
    fs.writeFileSync(file, JSON.stringify(ordered, null, 4) + '\n', 'utf8');
    console.log(`${loc}: +${added} keys (total ${Object.keys(ordered).filter(k => !k.startsWith('@')).length})`);
  }
}

main();
