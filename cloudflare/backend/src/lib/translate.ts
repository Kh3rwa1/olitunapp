// Translation engines shared by /api/v1/translate and the AI Studio.

// Language mappings for IndicTrans2 model
export const INDICTRANS2_TARGETS: Record<string, string> = {
  sat: 'sat_Olck',
  santali: 'sat_Olck',
  'sat-in': 'sat_Olck',
  'sat_olck': 'sat_Olck',
  hin: 'hin_Deva',
  hi: 'hin_Deva',
  hindi: 'hin_Deva',
  ben: 'ben_Beng',
  bn: 'ben_Beng',
  bengali: 'ben_Beng',
  ory: 'ory_Orya',
  or: 'ory_Orya',
  odia: 'ory_Orya',
  asm: 'asm_Beng',
  as: 'asm_Beng',
  guj: 'guj_Gujr',
  gu: 'guj_Gujr',
  mar: 'mar_Deva',
  mr: 'mar_Deva',
  pan: 'pan_Guru',
  pa: 'pan_Guru',
  tam: 'tam_Taml',
  ta: 'tam_Taml',
  tel: 'tel_Telu',
  te: 'tel_Telu',
  urd: 'urd_Arab',
  ur: 'urd_Arab',
  san: 'san_Deva',
  sa: 'san_Deva',
};

export async function computeCacheKey(from: string, to: string, text: string, engine: string): Promise<string> {
  const input = JSON.stringify({ from: from.toLowerCase(), to: to.toLowerCase(), text: text.trim(), engine: engine.toLowerCase() });
  const msgUint8 = new TextEncoder().encode(input);
  const hashBuffer = await crypto.subtle.digest('SHA-256', msgUint8);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
}

export async function translateWithGoogle(text: string, from = 'auto', to = 'sat'): Promise<{ translation: string; detectedLanguage: string; provider: string }> {
  const sl = from === 'auto' ? 'auto' : from;
  
  // 1. Primary: translate_a/single (matches @vitalets/google-translate-api)
  try {
    const url = 'https://translate.google.com/translate_a/single?client=at&dt=t&dt=rm&dj=1';
    const body = new URLSearchParams({ sl, tl: to, q: text }).toString();

    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8',
        'User-Agent': 'GoogleTranslate/6.28.0.05.421483610 (Linux; U; Android 12; Pixel 5)',
      },
      body,
    });

    if (res.ok) {
      const data: any = await res.json();
      const translation = (data?.sentences || [])
        .filter((s: any) => typeof s?.trans === 'string')
        .map((s: any) => s.trans)
        .join('')
        .trim();
      const detectedLanguage = data?.src || from;

      if (translation.length > 0) {
        return {
          translation,
          detectedLanguage,
          provider: 'google-translate',
        };
      }
    }
  } catch (_) {
    // try fallback endpoint
  }

  // 2. Secondary fallback: dict-chrome-ex GET endpoint
  const urlFallback = `https://clients5.google.com/translate_a/t?client=dict-chrome-ex&sl=${encodeURIComponent(sl)}&tl=${encodeURIComponent(to)}&q=${encodeURIComponent(text)}`;
  const resFallback = await fetch(urlFallback, {
    method: 'GET',
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    },
  });

  if (!resFallback.ok) {
    throw new Error(`Google Translate HTTP error ${resFallback.status}`);
  }

  const dataFallback: any = await resFallback.json();
  let translationFallback = '';
  let detectedLanguageFallback = from;

  if (Array.isArray(dataFallback)) {
    if (typeof dataFallback[0] === 'string') {
      translationFallback = dataFallback[0];
    } else if (Array.isArray(dataFallback[0])) {
      translationFallback = dataFallback[0][0] || '';
      detectedLanguageFallback = dataFallback[0][1] || from;
    }
  }

  if (!translationFallback || translationFallback.trim().length === 0) {
    throw new Error('Google Translate returned empty translation');
  }

  return {
    translation: translationFallback.trim(),
    detectedLanguage: detectedLanguageFallback,
    provider: 'google-translate',
  };
}

export async function translateWithWorkersAi(ai: any, text: string, targetTag: string): Promise<{ translation: string; provider: string }> {
  const res: any = await ai.run('@cf/ai4bharat/indictrans2-en-indic-1b', {
    text: text,
    target_language: targetTag,
  });
  const translation = res?.translations?.[0] || res?.result?.translations?.[0] || res?.translation;
  if (!translation || typeof translation !== 'string') {
    throw new Error('Workers AI returned empty translation');
  }
  return {
    translation: translation.trim(),
    provider: 'cloudflare-indictrans2-ai',
  };
}

export async function translateWithAiLlama(ai: any, text: string, from: string, to: string): Promise<{ translation: string; provider: string }> {
  const res: any = await ai.run('@cf/meta/llama-3.2-3b-instruct', {
    messages: [
      {
        role: 'system',
        content: 'You are an accurate translator. Translate the text into the target language faithfully. Output ONLY the translation. Never add any notes, commentary, markdown formatting, or quotes.',
      },
      {
        role: 'user',
        content: `Translate this text from ${from} to ${to}:\n${text}`,
      },
    ],
    max_tokens: 256,
  });
  const response = res?.response || res?.result?.response || '';
  if (!response || typeof response !== 'string') {
    throw new Error('Llama AI translation returned empty');
  }
  return {
    translation: response.trim().replace(/^["']|["']$/g, ''),
    provider: 'cloudflare-llama3-ai',
  };
}

export const M2M100_LANGS: Record<string, string> = {
  en: 'english',
  hi: 'hindi',
  bn: 'bengali',
  or: 'oriya',
  mr: 'marathi',
  gu: 'gujarati',
  pa: 'punjabi',
  ta: 'tamil',
  te: 'telugu',
  ur: 'urdu',
  es: 'spanish',
  fr: 'french',
  de: 'german',
  zh: 'chinese',
  ja: 'japanese',
  ru: 'russian',
  ar: 'arabic',
};

export async function translateWithM2M100(ai: any, text: string, from: string, to: string): Promise<{ translation: string; provider: string }> {
  const srcLang = M2M100_LANGS[from.toLowerCase()] || 'english';
  const tgtLang = M2M100_LANGS[to.toLowerCase()] || to;
  const res: any = await ai.run('@cf/meta/m2m100-1.2b', {
    text: text,
    source_lang: srcLang,
    target_lang: tgtLang,
  });
  const translation = res?.translated_text;
  if (!translation || typeof translation !== 'string') {
    throw new Error('m2m100 returned empty translation');
  }
  return {
    translation: translation.trim(),
    provider: 'cloudflare-m2m100-ai',
  };
}
