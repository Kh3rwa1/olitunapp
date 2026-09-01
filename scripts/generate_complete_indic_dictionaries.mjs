import fs from "fs";

// 1. Curated dictionary of all conversational sentences in Santali courses
const sentenceTranslations = {
  // Basics & Introductions
  "what is your name?": { bn: "তোমার নাম কী?", hi: "तुम्हारा नाम क्या है?", or: "ତୁମର ନାମ କ’ଣ?", en: "What is your name?" },
  "my name is santhal": { bn: "আমার নাম সাঁওতাল", hi: "मेरा नाम संताल है", or: "ମୋର ନାମ ସାନ୍ତାଳ", en: "My name is Santhal" },
  "where are you going?": { bn: "তুমি কোথায় যাচ্ছো?", hi: "तुम कहाँ जा रहे हो?", or: "ତୁମେ କୁଆଡ଼େ ଯାଉଛ?", en: "Where are you going?" },
  "where do you live?": { bn: "তুমি কোথায় থাকো?", hi: "तुम कहाँ रहते हो?", or: "ତୁମେ କେଉଁଠି ରହୁଛ?", en: "Where do you live?" },
  "i live here": { bn: "আমি এখানে থাকি", hi: "मैं यहाँ रहता हूँ", or: "ମୁଁ ଏଠାରେ ରହେ", en: "I live here" },
  "i am going": { bn: "আমি যাচ্ছি", hi: "मैं जा रहा हूँ", or: "ମୁଁ ଯାଉଛି", en: "I am going" },
  "who are you?": { bn: "তুমি কে?", hi: "तुम कौन हो?", or: "ତୁମେ କିଏ?", en: "Who are you?" },
  "i am a student": { bn: "আমি একজন শিক্ষার্থী", hi: "मैं एक छात्र हूँ", or: "ମୁଁ ଜଣେ ଛାତ୍ର", en: "I am a student" },
  "what is this?": { bn: "এটি কী?", hi: "यह क्या है?", or: "ଏହା କ’ଣ?", en: "What is this?" },
  "that is a book": { bn: "ওটি একটি বই", hi: "वह एक किताब है", or: "ତାହା ଏକ ବହି", en: "That is a book" },
  "can you speak santali?": { bn: "তুমি কি সাঁওতালি বলতে পারো?", hi: "क्या तुम संताली बोल सकते हो?", or: "ତୁମେ ସାନ୍ତାଳୀ କହିପାରିବ କି?", en: "Can you speak Santali?" },
  "yes, i can speak a little": { bn: "হ্যাঁ, আমি একটু একটু বলতে পারি", hi: "हाँ, मैं थोड़ा-थोड़ा बोल सकता हूँ", or: "ହଁ, ମୁଁ ଟିକେ ଟିକେ କହିପାରିବି", en: "Yes, I can speak a little" },
  "this is my friend": { bn: "ইনি আমার বন্ধু", hi: "यह मेरा दोस्त है", or: "ଏ ମୋର ବନ୍ଧୁ", en: "This is my friend" },
  "how old are you?": { bn: "তোমার বয়স কত?", hi: "तुम्हारी उम्र कितनी है?", or: "ତୁମର ବୟସ କେତେ?", en: "How old are you?" },
  "i am twenty years old": { bn: "আমার বয়স কুড়ি বছর", hi: "मेरी उम्र बीस साल है", or: "ମୋର ବୟସ କୋଡ଼ିଏ ବର୍ଷ", en: "I am twenty years old" },
  "where are you from?": { bn: "তুমি কোথা থেকে এসেছ?", hi: "तुम कहाँ से आए हो?", or: "ତୁମେ କେଉଁଠାରୁ ଆସିଛ?", en: "Where are you from?" },
  "where did you come from?": { bn: "তুমি কোথা থেকে এলে?", hi: "तुम कहाँ से आए?", or: "ତୁମେ କେଉଁଠାରୁ ଆସିଲ?", en: "Where did you come from?" },
  "i came from the village": { bn: "আমি গ্রাম থেকে এসেছি", hi: "मैं गाँव से आया हूँ", or: "ମୁଁ ଗାଁରୁ ଆସିଲି", en: "I came from the village" },
  "i am from jharkhand": { bn: "আমি ঝাড়খণ্ড থেকে এসেছি", hi: "मैं झारखंड से हूँ", or: "ମୁଁ ଝାଡ଼ଖଣ୍ଡରୁ ଆସିଛି", en: "I am from Jharkhand" },
  "this is my house": { bn: "এটি আমার বাড়ি", hi: "यह मेरा घर है", or: "ଏହା ମୋର ଘର", en: "This is my house" },
  "this is a tree": { bn: "এটি একটি গাছ", hi: "यह एक पेड़ है", or: "ଏହା ଏକ ଗଛ", en: "This is a tree" },
  "where do you work?": { bn: "তুমি কোথায় কাজ করো?", hi: "तुम कहाँ काम करते हो?", or: "ତୁମେ କେଉଁଠି କାମ କରୁଛ?", en: "Where do you work?" },
  "do you work?": { bn: "তুমি কি কাজ করো?", hi: "क्या तुम काम करते हो?", or: "ତୁମେ କାମ କର କି?", en: "Do you work?" },
  "yes, i work": { bn: "হ্যাঁ, আমি কাজ করি", hi: "हाँ, मैं काम करता हूँ", or: "ହଁ, ମୁଁ କାମ କରେ", en: "Yes, I work" },
  "i work at a school": { bn: "আমি স্কুলে কাজ করি", hi: "मैं स्कूल में काम करता हूँ", or: "ମୁଁ ବିଦ୍ୟାଳୟରେ କାମ କରେ", en: "I work at a school" },
  "what do you like?": { bn: "তুমি কী পছন্দ করো?", hi: "तुम्हें क्या पसंद है?", or: "ତୁମେ କ’ଣ ପସନ୍ଦ କର?", en: "What do you like?" },
  "i like speaking santali": { bn: "আমি সাঁওতালিতে কথা বলতে পছন্দ করি", hi: "मुझे संताली बोलना पसंद है", or: "ମୋତେ ସାନ୍ତାଳୀ କହିବା ପସନ୍ଦ", en: "I like speaking Santali" },
  "he is my younger brother": { bn: "সে আমার ছোট ভাই", hi: "वह मेरा छोटा भाई है", or: "ସେ ମୋର ସାନଭାଇ", en: "He is my younger brother" },
  "where is he/she?": { bn: "সে কোথায় আছে?", hi: "वह कहाँ है?", or: "ସେ କେଉଁଠି ଅଛି?", en: "Where is he/she?" },
  "he/she is at home": { bn: "সে বাড়িতে আছে", hi: "वह घर पर है", or: "ସେ ଘରେ ଅଛି", en: "He/she is at home" },
  "do you see me?": { bn: "তুমি কি আমাকে দেখতে পাচ্ছ?", hi: "क्या तुम मुझे देख रहे हो?", or: "ତୁମେ ମୋତେ ଦେଖୁଛ କି?", en: "Do you see me?" },
  "i am hungry": { bn: "আমার খিদে পেয়েছে", hi: "मुझे भूख लगी है", or: "ମୋତେ ଭୋକ ଲାଗୁଛି", en: "I am hungry" },
  "please eat food": { bn: "দয়া করে খাবার খাও", hi: "कृपया खाना खाओ", or: "ଦୟାକରି ଖାଦ୍ୟ ଖାଅ", en: "Please eat food" },
  "please drink water": { bn: "দয়া করে জল খাও", hi: "कृपया पानी पियो", or: "ଦୟାକରି ପାଣି ପିଅ", en: "Please drink water" },
  "i am studying": { bn: "আমি পড়াশোনা করছি", hi: "मैं पढ़ाई कर रहा हूँ", or: "ମୁଁ ପଢ଼ୁଛି", en: "I am studying" },
  "what are you doing?": { bn: "তুমি কী করছ?", hi: "तुम क्या कर रहे हो?", or: "ତୁମେ କ’ଣ କରୁଛ?", en: "What are you doing?" },
  "i am working": { bn: "আমি কাজ করছি", hi: "मैं काम कर रहा हूँ", or: "ମୁଁ କାମ କରୁଛି", en: "I am working" },
  "let's go": { bn: "চলো যাই", hi: "चलो चलें", or: "ଚାଲ ଯିବା", en: "Let's go" },
  "come here": { bn: "এখানে এসো", hi: "यहाँ आओ", or: "ଏଠାକୁ ଆସ", en: "Come here" },
  "i am going to sleep": { bn: "আমি ঘুমাতে যাচ্ছি", hi: "मैं सोने जा रहा हूँ", or: "ମୁଁ ଶୋଇବାକୁ ଯାଉଛି", en: "I am going to sleep" },
  "are you very busy today?": { bn: "তুমি কি আজ খুব ব্যস্ত?", hi: "क्या तुम आज बहुत व्यस्त हो?", or: "ତୁମେ ଆଜି ବହୁତ ବ୍ୟସ୍ତ କି?", en: "Are you very busy today?" },
  "i am not busy": { bn: "আমি ব্যস্ত নই", hi: "मैं व्यस्त नहीं हूँ", or: "ମୁଁ ବ୍ୟସ୍ତ ନୁହେଁ", en: "I am not busy" },
  "please wait for me a little": { bn: "দয়া করে আমার জন্য একটু অপেক্ষা করো", hi: "कृपया मेरा थोड़ा इंतजार करें", or: "ଦୟାକରି ମୋ ପାଇଁ ଟିକେ ଅପେକ୍ଷା କର", en: "Please wait for me a little" },
  "do you like singing?": { bn: "তুমি কি গান গাইতে পছন্দ করো?", hi: "क्या तुम्हें गाना पसंद है?", or: "ତୁମେ ଗୀତ ଗାଇବାକୁ ଭଲ ପାଅ କି?", en: "Do you like singing?" },
  "yes, i like singing very much": { bn: "হ্যাঁ, আমি গান গাইতে খুব পছন্দ করি", hi: "हाँ, मुझे गाना बहुत पसंद है", or: "ହଁ, ମୁଁ ଗୀତ ଗାଇବାକୁ ବହୁତ ଭଲ ପାଏ", en: "Yes, I like singing very much" },
  "what's the news?": { bn: "কী খবর?", hi: "क्या खबर है?", or: "କ’ଣ ଖବର?", en: "What's the news?" },
  "everything is fine": { bn: "সবকিছু ভালো আছে", hi: "सब ठीक है", or: "ସବୁ ଠିକ୍ ଅଛି", en: "Everything is fine" },
  "when will you return?": { bn: "তুমি কখন ফিরবে?", hi: "तुम कब लौटोगे?", or: "ତୁମେ କେବେ ଫେରିବ?", en: "When will you return?" },
  "i will return tomorrow": { bn: "আমি আগামীকাল ফিরব", hi: "मैं कल लौटूँगा", or: "ମୁଁ କାଲି ଫେରିବି", en: "I will return tomorrow" },
  "do you know how to play the drum?": { bn: "তুমি কি মাদল বাজাতে জানো?", hi: "क्या तुम मांदर बजाना जानते हो?", or: "ତୁମେ ମାଦଳ ବଜାଇବା ଜାଣିଛ କି?", en: "Do you know how to play the drum?" },
  "i do not know": { bn: "আমি জানি না", hi: "मुझे नहीं पता", or: "ମୁଁ ଜାଣିନାହିଁ", en: "I do not know" },
  "please teach me": { bn: "দয়া করে আমাকে শেখাও", hi: "कृपया मुझे सिखाएं", or: "ଦୟାକରି ମୋତେ ଶିଖାନ୍ତୁ", en: "Please teach me" },
  "yes, i will teach you tomorrow": { bn: "হ্যাঁ, আগামীকাল আমি তোমাকে শেখাব", hi: "हाँ, मैं कल तुम्हें सिखाऊँगा", or: "ହଁ, ମୁଁ ଆସନ୍ତାକାଲି ତୁମକୁ ଶିଖାଇବି", en: "Yes, I will teach you tomorrow" },
  "today is a very joyful day": { bn: "আজ খুব আনন্দের দিন", hi: "आज बहुत खुशी का दिन है", or: "ଆଜି ବହୁତ ଖୁସିର ଦିନ", en: "Today is a very joyful day" },
  "come to our house": { bn: "আমাদের বাড়ি এসো", hi: "हमारे घर आओ", or: "ଆମ ଘରକୁ ଆସ", en: "Come to our house" },
  "i will come tomorrow": { bn: "আমি আগামীকাল আসব", hi: "मैं कल आऊँगा", or: "ମୁଁ କାଲି ଆସିବି", en: "I will come tomorrow" },
  "give me your ol chiki book": { bn: "তোমার অল চিকি বইটি আমাকে দাও", hi: "अपनी ओल चिकी किताब मुझे दो", or: "ତୁମର ଅଲ ଚିକି ବହି ମୋତେ ଦିଅ", en: "Give me your Ol Chiki book" },
  "this is my book": { bn: "এটি আমার বই", hi: "यह मेरी किताब है", or: "ଏହା ମୋର ବହି", en: "This is my book" },
  "do you like blowing the flute?": { bn: "তুমি কি বাঁশি বাজাতে পছন্দ করো?", hi: "क्या तुम्हें बाँसुरी बजाना पसंद है?", or: "ତୁମେ ବଂଶୀ ବଜାଇବାକୁ ଭଲ ପାଅ କି?", en: "Do you like blowing the flute?" },
  "yes, blowing the flute is very sweet": { bn: "হ্যাঁ, বাঁশি বাজানো খুব মধুর", hi: "हाँ, बाँसुरी बजाना बहुत मधुर है", or: "ହଁ, ବଂଶୀ ବଜାଇବା ବହୁତ ମଧୁର", en: "Yes, blowing the flute is very sweet" },
  "why are you laughing?": { bn: "তুমি হাসছ কেন?", hi: "तुम क्यों हंस रहे हो?", or: "ତୁମେ କାହିଁକି ହସୁଛ?", en: "Why are you laughing?" },
  "i became happy, that's why": { bn: "আমি খুশি হয়েছি, তাই", hi: "मुझे खुशी हुई, इसलिए", or: "ମୋତେ ଖୁସି ଲାଗିଲା, ସେଥିପାଇଁ", en: "I became happy, that's why" },
  "friend, we will meet tomorrow": { bn: "বন্ধু, আগামীকাল আমাদের দেখা হবে", hi: "दोस्त, हम कल मिलेंगे", or: "ବନ୍ଧୁ, ଆମେ କାଲି ଦେଖା ହେବା", en: "Friend, we will meet tomorrow" },

  // Courtesies & Greetings
  "hello, how are you?": { bn: "জোহার, তুমি কেমন আছো?", hi: "नमस्ते, आप कैसे हैं?", or: "ନମସ୍କାର, ତୁମେ କେମିତି ଅଛ?", en: "Hello, how are you?" },
  "i am fine": { bn: "আমি ভালো আছি", hi: "मैं ठीक हूँ", or: "ମୁଁ ଭଲ ଅଛି", en: "I am fine" },
  "good morning": { bn: "সুপ্রভাত", hi: "सुप्रभात", or: "ଶୁଭ ସକାଳ", en: "Good morning" },
  "good night": { bn: "শুভ রাত্রি", hi: "शुभ रात्रि", or: "ଶୁଭ ରାତ୍ରି", en: "Good night" },
  "excuse me / sorry": { bn: "ক্ষমা করবেন", hi: "माफ़ कीजिए", or: "କ୍ଷମା କରିବେ", en: "Excuse me / Sorry" },
  "excuse me": { bn: "শুনুন / মাফ করবেন", hi: "माफ़ कीजिए", or: "କ୍ଷମା କରିବେ", en: "Excuse me" },
  "sorry": { bn: "দুঃখিত", hi: "माफ़ करना", or: "ଦୁଃଖିତ", en: "Sorry" },
  "take care": { bn: "নিজের যত্ন নিয়ো", hi: "अपना ख्याल रखना", or: "ନିଜର ଯତ୍ନ ନିଅ", en: "Take care" },
  "please sit down": { bn: "দয়া করে বসুন", hi: "कृपया बैठिए", or: "ଦୟାକରି ବସନ୍ତୁ", en: "Please sit down" },
  "welcome, come inside the house": { bn: "স্বাগতম, ঘরের ভেতরে আসুন", hi: "स्वागत है, घर के अंदर आइए", or: "ସ୍ୱାଗତ, ଘର ଭିତରକୁ ଆସନ୍ତୁ", en: "Welcome, come inside the house" },
  "i am very happy to meet you": { bn: "আপনার সাথে দেখা হয়ে খুব আনন্দ হলো", hi: "आपसे मिलकर बहुत खुशी हुई", or: "ଆପଣଙ୍କୁ ଭେଟି ବହୁତ ଖୁସି ଲାଗିଲା", en: "I am very happy to meet you" },
  "thank you very much": { bn: "আপনাকে অনেক ধন্যবাদ", hi: "बहुत-बहुत धन्यवाद", or: "ଅଶେଷ ଧନ୍ୟବାଦ", en: "Thank you very much" },
  "thank you": { bn: "ধন্যবাদ", hi: "धन्यवाद", or: "ଧନ୍ୟବାଦ", en: "Thank you" },
  "you are welcome": { bn: "স্বাগতম", hi: "आपका स्वागत है", or: "ଆପଣଙ୍କୁ ସ୍ୱାଗତ", en: "You are welcome" },
  "see you again": { bn: "আবার দেখা হবে", hi: "फिर मिलेंगे", or: "ପୁଣି ଦେଖା ହେବା", en: "See you again" },
  "have a good day": { bn: "আপনার দিনটি শুভ হোক", hi: "आपका दिन शुभ हो", or: "ଆପଣଙ୍କ ଦିନ ଶୁଭ ହେଉ", en: "Have a good day" },

  // Time & Weather
  "what time is it?": { bn: "এখন কটা বাজে?", hi: "कितने बजे हैं?", or: "କେତେ ସମୟ ହେଲାଣି?", en: "What time is it?" },
  "it is ten o'clock": { bn: "এখন দশটা বাজে", hi: "दस बजे हैं", or: "ଦଶଟା ବାଜିଛି", en: "It is ten o'clock" },
  "it is raining": { bn: "বৃষ্টি হচ্ছে", hi: "बारिश हो रही है", or: "ବର୍ଷା ହେଉଛି", en: "It is raining" },
  "the sun is shining bright": { bn: "সূর্য উজ্জ্বলভাবে কিরণ দিচ্ছে", hi: "सूरज चमक रहा है", or: "ସୂର୍ଯ୍ୟ ଉଜ୍ଜ୍ୱଳ ଭାବରେ ଚମକୁଛି", en: "The sun is shining bright" },
  "it is very cold today": { bn: "আজ খুব ঠান্ডা", hi: "आज बहुत ठंड है", or: "ଆଜି ବହୁତ ଥଣ୍ଡା", en: "It is very cold today" },
  "it is very hot today": { bn: "আজ খুব গরম", hi: "आज बहुत गर्मी है", or: "ଆଜି ବହୁତ ଗରମ", en: "It is very hot today" },
  "today is a beautiful day": { bn: "আজকের দিনটি খুব সুন্দর", hi: "आज बहुत अच्छा दिन है", or: "ଆଜି ବହୁତ ଭଲ ଦିନ", en: "Today is a beautiful day" },
  "the wind is blowing": { bn: "বাতাস বইছে", hi: "हवा चल रही है", or: "ପବନ ବହୁଛି", en: "The wind is blowing" },
  "the sky is clear": { bn: "আকাশ পরিষ্কার", hi: "आसमान साफ है", or: "ଆକାଶ ନିର୍ମଳ ଅଛି", en: "The sky is clear" },
  "clouds are gathering in the sky": { bn: "আকাশে মেঘ জমছে", hi: "आसमान में बादल छा रहे हैं", or: "ଆକାଶରେ ମେଘ ଘୋଟି ଆସୁଛି", en: "Clouds are gathering in the sky" },

  // Market & Shopping
  "how much is this?": { bn: "এটার দাম কত?", hi: "इसका दाम कितना है?", or: "ଏହାର ମୂଲ୍ୟ କେତେ?", en: "How much is this?" },
  "i will buy this": { bn: "আমি এটি কিনব", hi: "मैं यह खरीदूँगा", or: "ମୁଁ ଏହା କିଣିବି", en: "I will buy this" },
  "is there a weekly market today?": { bn: "আজ কি সাপ্তাহিক হাট আছে?", hi: "क्या आज साप्ताहिक हाट है?", or: "ଆଜି ସାପ୍ତାହିକ ହାଟ ଅଛି କି?", en: "Is there a weekly market today?" },
  "this is very good fruit": { bn: "এটি খুব ভালো ফল", hi: "यह बहुत अच्छा फल है", or: "ଏହା ବହୁତ ଭଲ ଫଳ", en: "This is very good fruit" },
  "please lower the price a little": { bn: "দয়া করে দাম একটু কমান", hi: "कृपया दाम थोड़ा कम करें", or: "ଦୟାକରି ଦାମ୍ ଟିକେ କମ କରନ୍ତୁ", en: "Please lower the price a little" },

  // Travel & Nature
  "where does this road go?": { bn: "এই রাস্তাটি কোথায় যায়?", hi: "यह रास्ता कहाँ जाता है?", or: "ଏହି ରାସ୍ତା କୁଆଡ଼େ ଯାଏ?", en: "Where does this road go?" },
  "this road goes to the market": { bn: "এই রাস্তাটি বাজারে যায়", hi: "यह रास्ता बाज़ार जाता है", or: "ଏହି ରାସ୍ତା ବଜାରକୁ ଯାଏ", en: "This road goes to the market" },
  "let's walk in the forest": { bn: "চলো বনে হাঁটি", hi: "चलो जंगल में टहलते हैं", or: "ଚାଲ ଜଙ୍ଗଲରେ ବୁଲିବା", en: "Let's walk in the forest" },
  "the river water is very sweet": { bn: "নদীর জল খুব মিষ্টি", hi: "नदी का पानी बहुत मीठा है", or: "ନଦୀ ପାଣି ବହୁତ ମିଠା", en: "The river water is very sweet" },
  "the birds are singing in the trees": { bn: "গাছে পাখিরা গান গাইছে", hi: "पेड़ों पर चिड़ियाँ गा रही हैं", or: "ଗଛରେ ଚଢ଼େଇମାନେ ଗାଉଛନ୍ତି", en: "The birds are singing in the trees" },

  // Folk Wisdom & Culture
  "going on the cultural path is the honor of the santal people.": { bn: "সংস্কৃতির পথে চলা সাঁওতাল জাতির গৌরব।", hi: "संस्कृति के मार्ग पर चलना संताल समाज का गौरव है।", or: "ସଂସ୍କୃତିର ବାଟରେ ଚାଲିବା ସାନ୍ତାଳ ଜାତିର ଗୌରବ।", en: "Going on the cultural path is the honor of the Santal people." },
  "going on the cultural path is the honor of the santal people": { bn: "সংস্কৃতির পথে চলা সাঁওতাল জাতির গৌরব।", hi: "संस्कृति के मार्ग पर चलना संताल समाज का गौरव है।", or: "ସଂସ୍କୃତିର ବାଟରେ ଚାଲିବା ସାନ୍ତାଳ ଜାତିର ଗୌରବ।", en: "Going on the cultural path is the honor of the Santal people." },
  "living life with pure traditions is righteousness.": { bn: "পবিত্র পরম্পরা অনুসারে জীবনযাপন করাই প্রকৃত ধর্ম।", hi: "पवित्र परंपराओं के अनुसार जीवन जीना ही धर्म है।", or: "ପବିତ୍ର ପରମ୍ପରା ଅନୁଯାୟୀ ଜୀବନ ବିତାଇବା ହିଁ ଧର୍ମ।", en: "Living life with pure traditions is righteousness." },
  "living life with pure traditions is righteousness": { bn: "পবিত্র পরম্পরা অনুসারে জীবনযাপন করাই প্রকৃত ধর্ম।", hi: "पवित्र परंपराओं के अनुसार जीवन जीना ही धर्म है।", or: "ପବିତ୍ର ପରମ୍ପରା ଅନୁଯାୟୀ ଜୀବନ ବିତାଇବା ହିଁ ଧର୍ମ।", en: "Living life with pure traditions is righteousness." },
  "literature is the soul, therefore preserve santali literature.": { bn: "সাহিত্য হলো প্রাণ, তাই সাঁওতালি সাহিত্য রক্ষা করুন।", hi: "साहित्य आत्मा है, इसलिए संताली साहित्य को संजोकर रखें।", or: "ସାହିତ୍ୟ ହେଉଛି ଆତ୍ମା, ତେଣୁ ସାନ୍ତାଳୀ ସାହିତ୍ୟକୁ ବଞ୍ଚାଇ ରଖନ୍ତୁ।", en: "Literature is the soul, therefore preserve Santali literature." },
  "literature is the soul, therefore preserve santali literature": { bn: "সাহিত্য হলো প্রাণ, তাই সাঁওতালি সাহিত্য রক্ষা করুন।", hi: "साहित्य आत्मा है, इसलिए संताली साहित्य को संजोकर रखें।", or: "ସାହିତ୍ୟ ହେଉଛି ଆତ୍ମା, ତେଣୁ ସାନ୍ତାଳୀ ସାହିତ୍ୟକୁ ବଞ୍ଚାଇ ରଖନ୍ତୁ।", en: "Literature is the soul, therefore preserve Santali literature." },
  "according to the religion of nature, love the trees and animals.": { bn: "প্রকৃতি ধর্মের নিয়ম মেনে গাছ ও পশুদের ভালোবাসুন।", hi: "प्रकृति धर्म के अनुसार पेड़ों और जानवरों से प्रेम करें।", or: "ପ୍ରକୃତି ଧର୍ମ ଅନୁସାରେ ଗଛ ଓ ପଶୁମାନଙ୍କୁ ଭଲ ପାଆନ୍ତୁ।", en: "According to the religion of nature, love the trees and animals." },
  "the power of the land is our great strength; respect it.": { bn: "দেশের শক্তিই আমাদের প্রধান শক্তি, তাকে সম্মান করুন।", hi: "देश की शक्ति ही हमारी सबसे बड़ी ताकत है; इसका सम्मान करें।", or: "ଦେଶର ଶକ୍ତି ହିଁ ଆମର ବଡ଼ ଶକ୍ତି; ଏହାକୁ ସମ୍ମାନ କରନ୍ତୁ।", en: "The power of the land is our great strength; respect it." },
  "let the name of your village shine with your good name.": { bn: "আপনার ভালো নামের মাধ্যমে আপনার গ্রামের নাম উজ্জ্বল হোক।", hi: "अपने अच्छे नाम से अपने गाँव का नाम रोशन करें।", or: "ଆପଣଙ୍କର ଭଲ ନାମରେ ଗାଁର ନାମ ଉଜ୍ଜ୍ୱଳ ହେଉ।", en: "Let the name of your village shine with your good name." },
  "humanity is the greatest religion of all; serve the people.": { bn: "মানবতাই শ্রেষ্ঠ ধর্ম; মানুষের সেবা করুন।", hi: "मानवता ही सबसे बड़ा धर्म है; लोगों की सेवा करें।", or: "ମାନବତା ହିଁ ସବୁଠାରୁ ବଡ଼ ଧର୍ମ; ଲୋକଙ୍କର ସେବା କରନ୍ତୁ।", en: "Humanity is the greatest religion of all; serve the people." },
  "win the hearts of all villagers with your sweet words.": { bn: "আপনার মিষ্টি কথার মাধ্যমে সব গ্রামবাসীর মন জয় করুন।", hi: "अपनी मीठी बातों से सभी ग्रामीणों का दिल जीतें।", or: "ଆପଣଙ୍କର ମଧୁର କଥାରେ ସମସ୍ତ ଗ୍ରାମବାସୀଙ୍କ ମନ ଜିତନ୍ତୁ।", en: "Win the hearts of all villagers with your sweet words." },
  "if worked with an honest heart, all work will be successful.": { bn: "সৎ মনে কাজ করলে সব কাজই সফল হয়।", hi: "यदि सच्चे मन से काम किया जाए, तो सभी कार्य सफल होंगे।", or: "ସତ ମନରେ କାମ କଲେ ସବୁ କାମ ସଫଳ ହେବ।", en: "If worked with an honest heart, all work will be successful." },
  "today we have made very delicious food in our home.": { bn: "আজ আমরা আমাদের বাড়িতে খুব সুস্বাদু খাবার বানিয়েছি।", hi: "आज हमने अपने घर में बहुत स्वादिष्ट भोजन बनाया है।", or: "ଆଜି ଆମେ ଆମ ଘରେ ବହୁତ ସୁଆଦିଆ ଖାଦ୍ୟ ତିଆରି କରିଛୁ।", en: "Today we have made very delicious food in our home." },
  "your female friend is studying very well in school.": { bn: "তোমার বান্ধবী স্কুলে খুব ভালো পড়াশোনা করছে।", hi: "तुम्हारी सहेली स्कूल में बहुत अच्छी पढ़ाई कर रही है।", or: "ତୁମର ସାଙ୍ଗ ସ୍କୁଲରେ ବହୁତ ଭଲ ପଢ଼ୁଛି।", en: "Your female friend is studying very well in school." },
  "in our village, people live with joy by doing daily chores.": { bn: "আমাদের গ্রামে মানুষ রোজকার কাজ করে আনন্দে থাকে।", hi: "हमारे गाँव में लोग रोज़मर्रा के काम करके खुशी से रहते हैं।", or: "ଆମ ଗାଁରେ ଲୋକମାନେ ପ୍ରତିଦିନ କାମ କରି ଖୁସିରେ ରହନ୍ତି।", en: "In our village, people live with joy by doing daily chores." },
  "i became very happy to meet you on this auspicious day.": { bn: "এই শুভ দিনে আপনার সাথে দেখা হয়ে আমি খুব খুশি হয়েছি।", hi: "इस शुभ दिन पर आपसे मिलकर मुझे बहुत खुशी हुई।", or: "ଏହି ଶୁଭ ଦିନରେ ଆପଣଙ୍କୁ ଭେଟି ମୁଁ ବହୁତ ଖୁସି ହେଲି।", en: "I became very happy to meet you on this auspicious day." },
  "relieving your heart, forget all the sorrows.": { bn: "মন শান্ত করে সব দুঃখ ভুলে যাও।", hi: "मन को शांत करके सारे दुख भूल जाओ।", or: "ମନକୁ ଶାନ୍ତ କରି ସବୁ ଦୁଃଖ ଭୁଲିଯାଅ।", en: "Relieving your heart, forget all the sorrows." },
  "affectionate bonding keeps all of us united.": { bn: "স্নেহের বন্ধন আমাদের সবাইকে ঐক্যবদ্ধ রাখে।", hi: "स्नेहपूर्ण संबंध हम सबको एकजुट रखता है।", or: "ସ୍ନେହର ସମ୍ପର୍କ ଆମ ସମସ୍ତଙ୍କୁ ଏକାଠି ରଖେ।", en: "Affectionate bonding keeps all of us united." },
  "do not speak secret talks in front of everyone.": { bn: "গোপন কথা সবার সামনে বোলো না।", hi: "गुप्त बातें सबके सामने मत बोलो।", or: "ଗୁପ୍ତ କଥା ସମସ୍ତଙ୍କ ସାମ୍ନାରେ କୁହନ୍ତୁ ନାହିଁ।", en: "Do not speak secret talks in front of everyone." },
  "keep the teacher's education in your soul like writing on the heart.": { bn: "হৃদয়ে লেখার মতো গুরুর শিক্ষাকে প্রাণে ধারণ করো।", hi: "हृदय पर लिखने की तरह गुरु की शिक्षा को अपनी आत्मा में रखो।", or: "ହୃଦୟରେ ଲେଖିବା ପରି ଗୁରୁଙ୍କ ଶିକ୍ଷାକୁ ଆତ୍ମାରେ ସାଇତି ରଖ।", en: "Keep the teacher's education in your soul like writing on the heart." },
  "today we laughed so much as if dying of laughter.": { bn: "আজ আমরা হাসতে হাসতে লুটোপুটি খেয়েছি।", hi: "आज हम हँसते-हँसते लोटपोट हो गए।", or: "ଆଜି ଆମେ ହସି ହସି ବେଦମ ହୋଇଗଲୁ।", en: "Today we laughed so much as if dying of laughter." },
  "work is worship, therefore do your work with an honest heart.": { bn: "কাজই ধর্ম, তাই নিজের কাজ সৎ মনে করুন।", hi: "कर्म ही पूजा है, इसलिए अपना काम सच्चे मन से करें।", or: "କାମ ହିଁ ଧର୍ମ, ତେଣୁ ନିଜ କାମ ସତ ମନରେ କରନ୍ତୁ।", en: "Work is worship, therefore do your work with an honest heart." },
  "patriotism is the honor of a true santal.": { bn: "দেশপ্রেমই একজন প্রকৃত সাঁওতালের সম্মান।", hi: "देशप्रेम ही एक सच्चे संताल का सम्मान है।", or: "ଦେଶଭକ୍ତି ହିଁ ପ୍ରକୃତ ସାନ୍ତାଳର ଗୌରବ।", en: "Patriotism is the honor of a true Santal." },
  "by speaking the truth, you will find true peace in life.": { bn: "সত্য কথা বললে জীবনে প্রকৃত শান্তি পাবেন।", hi: "सच बोलने से आपको जीवन में सच्ची शांति मिलेगी।", or: "ସତ କହିଲେ ଜୀବନରେ ପ୍ରକୃତ ଶାନ୍ତି ମିଳିବ।", en: "By speaking the truth, you will find true peace in life." },
  "being welcomed, sit in our house friend.": { bn: "স্বাগতম বন্ধু, আমাদের ঘরে বসো।", hi: "स्वागत है दोस्त, हमारे घर में बैठो।", or: "ସ୍ୱାଗତ ବନ୍ଧୁ, ଆମ ଘରେ ବସ।", en: "Being welcomed, sit in our house friend." },
  "resting well, advance on your path of knowledge.": { bn: "ভালোভাবে বিশ্রাম নিয়ে তোমার জ্ঞানের পথে এগিয়ে যাও।", hi: "अच्छे से विश्राम करके अपने ज्ञान के मार्ग पर आगे बढ़ें।", or: "ଭଲ ଭାବରେ ବିଶ୍ରାମ ନେଇ ଜ୍ଞାନର ବାଟରେ ଆଗକୁ ବଢ଼।", en: "Resting well, advance on your path of knowledge." }
};

// 2. Curated dictionary of all vocabulary words
const wordTranslations = {
  // Family & People
  "father": { bn: "পিতা / বাবা", hi: "पिता / बापू", or: "ବାପା", en: "Father" },
  "mother": { bn: "মাতা / মা", hi: "माता / माँ", or: "ମାଆ", en: "Mother" },
  "baba": { bn: "পিতা / বাবা", hi: "पिता / बापू", or: "ବାପା", en: "Father" },
  "ayo": { bn: "মাতা / মা", hi: "माता / माँ", or: "ମାଆ", en: "Mother" },
  "brother": { bn: "ভাই", hi: "भाई", or: "ଭାଇ", en: "Brother" },
  "sister": { bn: "বোন", hi: "बहन", or: "ଭଉଣୀ", en: "Sister" },
  "elder brother": { bn: "দাদা / বড় ভাই", hi: "बड़ा भाई", or: "ବଡ଼ ଭାଇ", en: "Elder brother" },
  "younger brother": { bn: "ছোট ভাই", hi: "छोटा भाई", or: "ସାନ ଭାଇ", en: "Younger brother" },
  "elder sister": { bn: "দিদি / বড় বোন", hi: "बड़ी बहन", or: "ଅପା / ବଡ଼ ଭଉଣୀ", en: "Elder sister" },
  "younger sister": { bn: "ছোট বোন", hi: "छोटी बहन", or: "ସାନ ଭଉଣୀ", en: "Younger sister" },
  "friend": { bn: "বন্ধু", hi: "दोस्त / मित्र", or: "ବନ୍ଧୁ / ସାଙ୍ଗ", en: "Friend" },
  "boy": { bn: "ছেলে / বালক", hi: "लड़का", or: "ପୁଅ / ବାଳକ", en: "Boy" },
  "girl": { bn: "মেয়ে / বালিকা", hi: "लड़की", or: "ଝିଅ / ବାଳିକା", en: "Girl" },
  "man": { bn: "পুরুষ / মানুষ", hi: "पुरुष / आदमी", or: "ପୁରୁଷ / ଲୋକ", en: "Man" },
  "woman": { bn: "মহিলা / নারী", hi: "महिला / औरत", or: "ମହିଳା / ନାରୀ", en: "Woman" },
  "child": { bn: "শিশু / বাচ্চা", hi: "बच्चा", or: "ପିଲା", en: "Child" },
  "children": { bn: "শিশুরা / বাচ্চারা", hi: "बच्चे", or: "ପିଲାମାନେ", en: "Children" },
  "family": { bn: "পরিবার", hi: "परिवार", or: "ପରିବାର", en: "Family" },

  // Nature, Animals & Surroundings
  "water": { bn: "জল / পানি", hi: "पानी / जल", or: "ପାଣି / ଜଳ", en: "Water" },
  "fire": { bn: "আগুন", hi: "आग / अग्नि", or: "ନିଆଁ", en: "Fire" },
  "earth": { bn: "মাটি / পৃথিবী", hi: "मिट्टी / पृथ्वी", or: "ମାଟି / ପୃଥିବୀ", en: "Earth" },
  "air": { bn: "বাতাস / বায়ু", hi: "हवा / वायु", or: "ପବନ / ବାୟୁ", en: "Air" },
  "sun": { bn: "সূর্য", hi: "सूरज / सूर्य", or: "ସୂର୍ଯ୍ୟ", en: "Sun" },
  "moon": { bn: "চাঁদ", hi: "चाँद / चंद्रमा", or: "ଚନ୍ଦ୍ର / ଜହ୍ନ", en: "Moon" },
  "star": { bn: "তারা / নক্ষত্র", hi: "तारा", or: "ତାରା", en: "Star" },
  "tree": { bn: "গাছ / বৃক্ষ", hi: "पेड़ / वृक्ष", or: "ଗଛ", en: "Tree" },
  "leaf": { bn: "পাতা", hi: "पत्ता", or: "ପତ୍ର", en: "Leaf" },
  "flower": { bn: "ফুল", hi: "फूल / पुष्प", or: "ଫୁଲ", en: "Flower" },
  "fruit": { bn: "ফল", hi: "फल", or: "ଫଳ", en: "Fruit" },
  "forest": { bn: "বন / জঙ্গল", hi: "जंगल / वन", or: "ଜଙ୍ଗଲ / ବଣ", en: "Forest" },
  "river": { bn: "নদী", hi: "नदी", or: "ନଦୀ", en: "River" },
  "mountain": { bn: "পাহাড় / পর্বত", hi: "पहाड़ / पर्वत", or: "ପାହାଡ଼ / ପର୍ବତ", en: "Mountain" },
  "stone": { bn: "পাথর", hi: "पत्थर", or: "ପଥର", en: "Stone" },
  "village": { bn: "গ্রাম / গাঁ", hi: "गाँव / ग्राम", or: "ଗାଁ / ଗ୍ରାମ", en: "Village" },
  "house": { bn: "ঘর / বাড়ি", hi: "ঘর / বাড়ি", or: "ଘର", en: "House" },
  "road": { bn: "পথ / রাস্তা", hi: "রাস্তা / সড়ক", or: "ରାସ୍ତା / ବାଟ", en: "Road" },
  "bird": { bn: "পাখি", hi: "चिड़िया / पक्षी", or: "ଚଢ଼େଇ / ପକ୍ଷୀ", en: "Bird" },
  "dog": { bn: "কুকুর", hi: "कुत्ता", or: "କୁକୁର", en: "Dog" },
  "cat": { bn: "বিড়াল", hi: "बिल्ली", or: "ବିଲେଇ", en: "Cat" },
  "cow": { bn: "গরু", hi: "गाय", or: "ଗାଈ", en: "Cow" },
  "tiger": { bn: "বাঘ", hi: "बाघ", or: "ବାଘ", en: "Tiger" },
  "deer": { bn: "হরিণ", hi: "हिरण", or: "ହରିଣ", en: "Deer" },
  "crow": { bn: "কাক", hi: "कौआ", or: "କାଉ", en: "Crow" },
  "fox": { bn: "শিয়াল", hi: "लोमड़ी / सियार", or: "କୋକିଶିଆଳୀ", en: "Fox" },
  "fish": { bn: "মাছ", hi: "मछली", or: "ମାଛ", en: "Fish" },

  // Food, Objects & Daily Life
  "food": { bn: "খাবার / অন্ন", hi: "खाना / भोजन", or: "ଖାଦ୍ୟ / ଭାତ", en: "Food" },
  "rice": { bn: "চাল / ভাত", hi: "चावल / भात", or: "ଚାଉଳ / ଭାତ", en: "Rice" },
  "salt": { bn: "নুন / লবণ", hi: "नमक", or: "ଲୁଣ", en: "Salt" },
  "milk": { bn: "দুধ", hi: "दूध", or: "କ୍ଷୀର", en: "Milk" },
  "book": { bn: "বই / পুস্তক", hi: "किताब / पुस्तक", or: "ବହି / ପୁସ୍ତକ", en: "Book" },
  "school": { bn: "বিদ্যালয় / স্কুল", hi: "विद्यालय / स्कूल", or: "ବିଦ୍ୟାଳୟ / ସ୍କୁଲ", en: "School" },
  "drum": { bn: "মাদল / ঢাক", hi: "मांदर / ढोल", or: "ମାଦଳ / ଢୋଲ", en: "Drum" },
  "flute": { bn: "বাঁশি", hi: "बाँसुरी", or: "ବଂଶୀ", en: "Flute" },
  "song": { bn: "গান / গীতি", hi: "गीत / गाना", or: "ଗୀତ", en: "Song" },
  "dance": { bn: "নাচ / নৃত্য", hi: "नृत्य / नाच", or: "ନାଚ / ନୃତ୍ୟ", en: "Dance" },
  "love": { bn: "ভালোবাসা / স্নেহ", hi: "प्रेम / प्यार", or: "ଭଲପାଇବା / ସ୍ନେହ", en: "Love" },
  "peace": { bn: "শান্তি", hi: "शांति", or: "ଶାନ୍ତି", en: "Peace" },
  "joy": { bn: "আনন্দ / উল্লাস", hi: "आनंद / खुशी", or: "ଆନନ୍ଦ / ଖୁସି", en: "Joy" },
  "sorrow": { bn: "দুঃখ / বেদনা", hi: "दुख / शोक", or: "ଦୁଃଖ", en: "Sorrow" },
  "truth": { bn: "সত্য", hi: "सत्य / सच", or: "ସତ୍ୟ / ସତ", en: "Truth" },
  "work": { bn: "কাজ / কর্ম", hi: "काम / कार्य", or: "କାମ / କାର୍ଯ୍ୟ", en: "Work" },
  "time": { bn: "সময় / কাল", hi: "समय / काल", or: "ସମୟ / କାଳ", en: "Time" },
  "day": { bn: "দিন / দিবস", hi: "दिन / दिवस", or: "ଦିନ / ଦିବସ", en: "Day" },
  "night": { bn: "রাত / রাত্রি", hi: "রাত / रात्रि", or: "ରାତି / ରାତ୍ରି", en: "Night" },
  "today": { bn: "আজ / অদ্য", hi: "आज", or: "ଆଜି", en: "Today" },
  "tomorrow": { bn: "আগামীকাল", hi: "कल (आने वाला)", or: "ଆସନ୍ତାକାଲି", en: "Tomorrow" },
  "yesterday": { bn: "গতকাল", hi: "कल (बीता हुआ)", or: "ଗତକାଲି", en: "Yesterday" }
};

// 3. Generate clean Dart files under 600 lines
function generateSentencesDart() {
  const entries = Object.entries(sentenceTranslations);
  const mid = Math.ceil(entries.length / 2);
  const part1Entries = entries.slice(0, mid);
  const part2Entries = entries.slice(mid);

  function createPart(className, list) {
    const lines = [
      `/// Auto-generated sentence translations chunk for Indic languages.`,
      `class ${className} {`,
      `  const ${className}._();`,
      ``,
      `  static const Map<String, Map<String, String>> translations = {`
    ];

    for (const [key, val] of list) {
      const escapedKey = key.replace(/\\/g, "\\\\").replace(/'/g, "\\'");
      const bn = (val.bn || "").replace(/\\/g, "\\\\").replace(/'/g, "\\'");
      const hi = (val.hi || "").replace(/\\/g, "\\\\").replace(/'/g, "\\'");
      const or = (val.or || "").replace(/\\/g, "\\\\").replace(/'/g, "\\'");
      const en = (val.en || key).replace(/\\/g, "\\\\").replace(/'/g, "\\'");
      lines.push(`    '${escapedKey}': {'bn': '${bn}', 'hi': '${hi}', 'or': '${or}', 'en': '${en}'},`);
    }

    lines.push(`  };`);
    lines.push(`}`);
    lines.push(``);
    return lines.join("\n");
  }

  fs.writeFileSync("lib/core/languages/indic_translations_sentences_part1.dart", createPart("IndicTranslationsSentencesPart1", part1Entries));
  fs.writeFileSync("lib/core/languages/indic_translations_sentences_part2.dart", createPart("IndicTranslationsSentencesPart2", part2Entries));

  const aggregator = [
    `import 'indic_translations_sentences_part1.dart';`,
    `import 'indic_translations_sentences_part2.dart';`,
    ``,
    `/// Auto-generated aggregated sentence translations for Bengali, Hindi, Odia, and English.`,
    `class IndicTranslationsSentences {`,
    `  const IndicTranslationsSentences._();`,
    ``,
    `  static const Map<String, Map<String, String>> translations = {`,
    `    ...IndicTranslationsSentencesPart1.translations,`,
    `    ...IndicTranslationsSentencesPart2.translations,`,
    `  };`,
    `}`,
    ``
  ].join("\n");

  fs.writeFileSync("lib/core/languages/indic_translations_sentences.dart", aggregator);
}

function generateWordsDart() {
  const lines = [
    "/// Auto-generated comprehensive vocabulary word translations for Bengali, Hindi, Odia, and English.",
    "class IndicTranslationsWords {",
    "  const IndicTranslationsWords._();",
    "",
    "  static const Map<String, Map<String, String>> translations = {"
  ];

  for (const [key, val] of Object.entries(wordTranslations)) {
    const escapedKey = key.replace(/\\/g, "\\\\").replace(/'/g, "\\'");
    const bn = (val.bn || "").replace(/\\/g, "\\\\").replace(/'/g, "\\'");
    const hi = (val.hi || "").replace(/\\/g, "\\\\").replace(/'/g, "\\'");
    const or = (val.or || "").replace(/\\/g, "\\\\").replace(/'/g, "\\'");
    const en = (val.en || key).replace(/\\/g, "\\\\").replace(/'/g, "\\'");
    lines.push(`    '${escapedKey}': {'bn': '${bn}', 'hi': '${hi}', 'or': '${or}', 'en': '${en}'},`);
  }

  lines.push("  };");
  lines.push("}");
  lines.push("");
  return lines.join("\n");
}

generateSentencesDart();
fs.writeFileSync("lib/core/languages/indic_translations_words.dart", generateWordsDart());
console.log("Successfully generated modular translation dictionaries under 600 lines.");
