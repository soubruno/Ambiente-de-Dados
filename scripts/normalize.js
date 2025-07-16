const fs = require('fs');
const path = require('path');
const csv = require('csv-parser');
const fastcsv = require('fast-csv');

// Utilitário: adiciona ou retorna ID único para um valor com normalização
function getId(map, value) {
  // Normaliza o valor antes de verificar
  const normalizedValue = normalizeLanguageName(value);
  if (!normalizedValue) return null; // Não adiciona valores vazios
  
  if (!map.has(normalizedValue)) {
    map.set(normalizedValue, map.size + 1);
  }
  return map.get(normalizedValue);
}

// Função para normalizar nomes de linguagens (remove duplicatas similares)
function normalizeLanguageName(name) {
  if (!name) return '';
  
  name = name.trim();
  
  // Mapeia variações conhecidas para nomes padrão
  const languageMap = {
    'english': 'English',
    'french': 'French', 
    'français': 'French',
    'italian': 'Italian',
    'german': 'German',
    'spanish - spain': 'Spanish - Spain',
    'spanish': 'Spanish - Spain',
    'japanese': 'Japanese',
    'portuguese - brazil': 'Portuguese - Brazil',
    'portuguese': 'Portuguese',
    'portuguese - portugal': 'Portuguese - Portugal',
    'russian': 'Russian',
    'simplified chinese': 'Simplified Chinese',
    'simplified': 'Simplified Chinese',
    'traditional chinese': 'Traditional Chinese',
    'traditional': 'Traditional Chinese',
    'korean': 'Korean',
    'danish': 'Danish',
    'polish': 'Polish',
    'turkish': 'Turkish',
    'czech': 'Czech',
    'hungarian': 'Hungarian',
    'dutch': 'Dutch',
    'ukrainian': 'Ukrainian',
    'spanish - latin america': 'Spanish - Latin America',
    'arabic': 'Arabic',
    'norwegian': 'Norwegian',
    'romanian': 'Romanian',
    'swedish': 'Swedish',
    'thai': 'Thai',
    'vietnamese': 'Vietnamese',
    'finnish': 'Finnish',
    'bulgarian': 'Bulgarian',
    'greek': 'Greek',
    'hebrew': 'Hebrew',
    'slovakian': 'Slovak',
    'slovak': 'Slovak'
  };
  
  const lowerName = name.toLowerCase().trim();
  return languageMap[lowerName] || name;
}

// Função para converter data de string para formato YYYY-MM-DD
function parseDate(dateString) {
  if (!dateString || dateString.trim() === '') return null;
  
  try {
    // Remove vírgulas e espaços extras
    const cleanDate = dateString.replace(/,/g, '').trim();
    
    // Tenta diferentes formatos de data
    const date = new Date(cleanDate);
    
    // Verifica se a data é válida
    if (isNaN(date.getTime())) {
      console.warn(`Data inválida: ${dateString}`);
      return null;
    }
    
    // Retorna no formato YYYY-MM-DD
    return date.toISOString().split('T')[0];
  } catch (error) {
    console.warn(`Erro ao processar data: ${dateString}`);
    return null;
  }
}

// Função para extrair valores mínimo e máximo de estimated_owners
function parseEstimatedOwners(ownersString) {
  if (!ownersString) return { min: null, max: null };
  
  // Remove espaços e converte para lowercase
  const clean = ownersString.toLowerCase().trim();
  
  // Padrões comuns: "0 - 20,000", "20000", "100000+"
  if (clean.includes(' - ')) {
    const parts = clean.split(' - ');
    const min = parseInt(parts[0].replace(/[^\d]/g, '')) || 0;
    const max = parseInt(parts[1].replace(/[^\d]/g, '')) || null;
    return { min, max };
  } else if (clean.includes('+')) {
    const min = parseInt(clean.replace(/[^\d]/g, '')) || 0;
    return { min, max: null }; // Sem limite máximo
  } else {
    const value = parseInt(clean.replace(/[^\d]/g, '')) || 0;
    return { min: value, max: value };
  }
}

// Função para determinar se um jogo é gratuito baseado no preço
function isFreeGame(price) {
  return !price || price === 0 || price === '0' || price === 'Free';
}

// Função para extrair número de reviews positivas e negativas
function parseReviews(reviewString) {
  if (!reviewString) return { positive: 0, negative: 0 };
  
  // Formato comum: "Very Positive (1,234 reviews)" ou "Mixed (567 reviews)"
  const match = reviewString.match(/\(([0-9,]+)\s+reviews?\)/i);
  if (match) {
    const total = parseInt(match[1].replace(/,/g, '')) || 0;
    // Estimativa básica baseada no tipo de review
    const lowerReview = reviewString.toLowerCase();
    if (lowerReview.includes('very positive') || lowerReview.includes('overwhelmingly positive')) {
      return { positive: Math.round(total * 0.9), negative: Math.round(total * 0.1) };
    } else if (lowerReview.includes('positive')) {
      return { positive: Math.round(total * 0.8), negative: Math.round(total * 0.2) };
    } else if (lowerReview.includes('mixed')) {
      return { positive: Math.round(total * 0.6), negative: Math.round(total * 0.4) };
    } else if (lowerReview.includes('negative')) {
      return { positive: Math.round(total * 0.3), negative: Math.round(total * 0.7) };
    }
    return { positive: Math.round(total * 0.7), negative: Math.round(total * 0.3) };
  }
  return { positive: 0, negative: 0 };
}

// Função para dividir por vírgula e limpar
function splitAndClean(str) {
  if (!str) return [];
  return str.split(',').map(s => s.trim()).filter(Boolean);
}

// Função para limpar e normalizar nomes de linguagens
function cleanLanguageName(name) {
  if (!name) return '';
  
  // Remove caracteres de escape HTML
  name = name.replace(/&amp;lt;/g, '<')
             .replace(/&amp;gt;/g, '>')
             .replace(/&lt;/g, '<')
             .replace(/&gt;/g, '>')
             .replace(/&nbsp;/g, ' ');
  
  // Remove tags HTML e BBCode
  name = name.replace(/<[^>]*>/g, '')
             .replace(/\[b\]/g, '')
             .replace(/\[\/b\]/g, '')
             .replace(/\[strong\]/g, '')
             .replace(/\[\/strong\]/g, '');
  
  // Remove caracteres de quebra de linha e espaços extras
  name = name.replace(/\r\n/g, ' ')
             .replace(/\r/g, ' ')
             .replace(/\n/g, ' ')
             .replace(/\s+/g, ' ')
             .trim();
  
  // Remove pontuação estranha no final
  name = name.replace(/[;,\s]+$/, '');
  
  // Remove prefixos estranhos
  name = name.replace(/^#lang_/g, '');
  
  // Trata casos onde múltiplas linguagens estão concatenadas incorretamente
  // Exemplo: "English Dutch English" -> ["English", "Dutch"]
  if (name.includes(' ')) {
    const words = name.split(/\s+/);
    const knownLanguages = [
      'English', 'French', 'Italian', 'German', 'Spanish', 'Japanese', 
      'Portuguese', 'Russian', 'Chinese', 'Korean', 'Danish', 'Polish',
      'Turkish', 'Czech', 'Hungarian', 'Dutch', 'Ukrainian', 'Arabic',
      'Norwegian', 'Romanian', 'Swedish', 'Thai', 'Vietnamese', 'Finnish',
      'Bulgarian', 'Greek', 'Slovak', 'Hebrew', 'Simplified', 'Traditional'
    ];
    
    // Se encontrar múltiplas linguagens conhecidas, retorna apenas a primeira válida
    const validLanguages = words.filter(word => 
      knownLanguages.some(lang => word.toLowerCase().includes(lang.toLowerCase()))
    );
    
    if (validLanguages.length > 1) {
      // Se há múltiplas linguagens, preferimos a primeira
      return validLanguages[0];
    }
  }
  
  // Normaliza nomes específicos
  if (name.toLowerCase() === 'français') name = 'French';
  if (name.includes('(full audio)')) name = name.replace('(full audio)', '').trim();
  if (name.includes('(text only)')) name = name.replace('(text only)', '').trim();
  if (name.includes('(all with full audio support)')) name = name.replace('(all with full audio support)', '').trim();
  
  // Remove entradas inválidas
  if (name.length < 2 || name.match(/^[\s\-_]+$/)) return '';
  
  return name.trim();
}

// Função específica para processar arrays de linguagens/categorias do Steam
function parseStringArray(str) {
  if (!str) return [];
  
  // Remove espaços e verifica se é um array vazio
  str = str.trim();
  if (str === '[]' || str === '') return [];
  
  try {
    // Remove aspas externas se existirem
    if (str.startsWith('"') && str.endsWith('"')) {
      str = str.slice(1, -1);
    }
    
    // Se começa com [ e termina com ], é um array em formato de string
    if (str.startsWith('[') && str.endsWith(']')) {
      // Remove os colchetes
      str = str.slice(1, -1);
      
      // Se está vazio após remover colchetes, retorna array vazio
      if (str.trim() === '') return [];
      
      // Divide por vírgula e remove aspas simples
      let languages = str.split(',')
        .map(s => s.trim())
        .map(s => s.replace(/^'|'$/g, '')) // Remove aspas simples do início e fim
        .map(cleanLanguageName)
        .filter(Boolean);
      
      // Se há múltiplas linguagens em uma entrada, separa por \r\n
      let expandedLanguages = [];
      languages.forEach(lang => {
        if (lang.includes('\r\n') || lang.includes('\\r\\n')) {
          // Separa linguagens que estão juntas
          let parts = lang.split(/\r\n|\\r\\n/g)
            .map(cleanLanguageName)
            .filter(Boolean);
          expandedLanguages.push(...parts);
        } else {
          expandedLanguages.push(lang);
        }
      });
      
      return expandedLanguages;
    }
    
    // Se não é um array, trata como string simples separada por vírgula
    let languages = str.split(',')
      .map(s => s.trim())
      .map(cleanLanguageName)
      .filter(Boolean);
    
    // Expande linguagens que podem estar juntas
    let expandedLanguages = [];
    languages.forEach(lang => {
      if (lang.includes('\r\n') || lang.includes('\\r\\n')) {
        let parts = lang.split(/\r\n|\\r\\n/g)
          .map(cleanLanguageName)
          .filter(Boolean);
        expandedLanguages.push(...parts);
      } else {
        expandedLanguages.push(lang);
      }
    });
    
    return expandedLanguages;
  } catch (error) {
    console.warn(`Erro ao processar array: ${str}`, error);
    return [];
  }
}

const inputFile = path.join(__dirname, '..', 'data', 'games.csv');
const outputDir = path.join(__dirname, '..', 'output');
if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir);

// Dicionários para entidades únicas
const developers = new Map();
const publishers = new Map();
const categories = new Map();
const genres = new Map();
const tags = new Map();
const languages = new Map();

// Tabelas normalizadas
const games = [];
const game_developers = [];
const game_publishers = [];
const game_categories = [];
const game_genres = [];
const game_tags = [];
const game_supported_languages = [];
const game_full_audio_languages = [];
const media = [];

// Processamento
fs.createReadStream(inputFile)
  .pipe(csv())
  .on('data', (row) => {
    const game_id = row['AppID'];
    const estimatedOwners = parseEstimatedOwners(row['Estimated owners']);
    const reviews = parseReviews(row['Reviews']);
    const price = parseFloat(row['Price']) || 0;
    
    games.push({
      app_id: game_id,
      name: row['Name'],
      release_date: parseDate(row['Release date']),
      estimated_owners_min: estimatedOwners.min,
      estimated_owners_max: estimatedOwners.max,
      current_price: price,
      currency_id: 1, // USD por padrão
      peak_ccu: parseInt(row['Peak CCU']) || null,
      required_age: parseInt(row['Required age']) || 0,
      dlc_count: parseInt(row['DLC count']) || 0,
      about: row['About the game'],
      short_description: row['Short description'] || null,
      header_image_url: row['Header image'] || null,
      website_url: row['Website'] || null,
      support_url: row['Support url'] || null,
      metacritic_score: parseInt(row['Metacritic score']) || null,
      metacritic_url: row['Metacritic url'] || null,
      user_score: parseFloat(row['User score']) || null,
      positive_reviews: reviews.positive,
      negative_reviews: reviews.negative,
      achievements_count: parseInt(row['Achievements']) || 0,
      recommendations: parseInt(row['Recommendations']) || 0,
      average_playtime_forever: parseInt(row['Average playtime forever']) || 0,
      average_playtime_two_weeks: parseInt(row['Average playtime two weeks']) || 0,
      median_playtime_forever: parseInt(row['Median playtime forever']) || 0,
      median_playtime_two_weeks: parseInt(row['Median playtime two weeks']) || 0,
      game_status: 'active', // Padrão
      is_free: isFreeGame(price),
      controller_support: row['Controller support'] || null
    });

    // M2M (muitos para muitos)
    splitAndClean(row['Developers']).forEach(name =>
      game_developers.push({ game_id, developer_id: getId(developers, name) })
    );
    splitAndClean(row['Publishers']).forEach(name =>
      game_publishers.push({ game_id, publisher_id: getId(publishers, name) })
    );
    splitAndClean(row['Categories']).forEach(name =>
      game_categories.push({ game_id, category_id: getId(categories, name) })
    );
    splitAndClean(row['Genres']).forEach((name, index) =>
      game_genres.push({ 
        game_id, 
        genre_id: getId(genres, name),
        is_primary: index === 0 // Primeiro gênero é considerado primário
      })
    );
    splitAndClean(row['Tags']).forEach(name =>
      game_tags.push({ 
        game_id, 
        tag_id: getId(tags, name),
        votes: 0 // Padrão, pode ser atualizado posteriormente
      })
    );
    // Processa linguagens suportadas evitando duplicatas
    const supportedLanguageIds = new Set();
    parseStringArray(row['Supported languages']).forEach(name => {
      const languageId = getId(languages, name);
      if (languageId && !supportedLanguageIds.has(languageId)) {
        supportedLanguageIds.add(languageId);
        game_supported_languages.push({ 
          game_id, 
          language_id: languageId,
          interface_support: true,
          subtitles_support: true
        });
      }
    });
    
    // Processa linguagens com áudio completo evitando duplicatas
    const fullAudioLanguageIds = new Set();
    parseStringArray(row['Full audio languages']).forEach(name => {
      const languageId = getId(languages, name);
      if (languageId && !fullAudioLanguageIds.has(languageId)) {
        fullAudioLanguageIds.add(languageId);
        game_full_audio_languages.push({ game_id, language_id: languageId });
      }
    });

    // Mídia melhorada
    if (row['Screenshots']) {
      media.push({ 
        game_id, 
        media_type: 'screenshot', 
        url: row['Screenshots'],
        is_primary: false,
        order_index: 0
      });
    }
    if (row['Movies']) {
      media.push({ 
        game_id, 
        media_type: 'video', 
        url: row['Movies'],
        is_primary: false,
        order_index: 1
      });
    }
    if (row['Header image']) {
      media.push({ 
        game_id, 
        media_type: 'thumbnail', 
        url: row['Header image'],
        is_primary: true,
        order_index: -1
      });
    }
  })
  .on('end', () => {
    console.log('✔ Dados carregados. Salvando tabelas...');

    // Remove duplicatas das tabelas de relacionamento
    const uniqueGameDevelopers = Array.from(
      new Map(game_developers.map(item => [`${item.game_id}-${item.developer_id}`, item])).values()
    );
    
    const uniqueGamePublishers = Array.from(
      new Map(game_publishers.map(item => [`${item.game_id}-${item.publisher_id}`, item])).values()
    );
    
    const uniqueGameCategories = Array.from(
      new Map(game_categories.map(item => [`${item.game_id}-${item.category_id}`, item])).values()
    );
    
    const uniqueGameGenres = Array.from(
      new Map(game_genres.map(item => [`${item.game_id}-${item.genre_id}`, item])).values()
    );
    
    const uniqueGameTags = Array.from(
      new Map(game_tags.map(item => [`${item.game_id}-${item.tag_id}`, item])).values()
    );
    
    const uniqueGameSupportedLanguages = Array.from(
      new Map(game_supported_languages.map(item => [`${item.game_id}-${item.language_id}`, item])).values()
    );
    
    const uniqueGameFullAudioLanguages = Array.from(
      new Map(game_full_audio_languages.map(item => [`${item.game_id}-${item.language_id}`, item])).values()
    );
    
    const uniqueMedia = Array.from(
      new Map(media.map(item => [`${item.game_id}-${item.media_type}-${item.url}`, item])).values()
    );

    // Função para salvar CSV
    const saveCSV = (filename, data) =>
      fastcsv.write(data, { headers: true }).pipe(fs.createWriteStream(path.join(outputDir, filename)));

    saveCSV('games.csv', games);
    saveCSV('developers.csv', [...developers.entries()].map(([name, id]) => ({ id, name })));
    saveCSV('game_developers.csv', uniqueGameDevelopers);
    saveCSV('publishers.csv', [...publishers.entries()].map(([name, id]) => ({ id, name })));
    saveCSV('game_publishers.csv', uniqueGamePublishers);
    saveCSV('categories.csv', [...categories.entries()].map(([name, id]) => ({ id, name })));
    saveCSV('game_categories.csv', uniqueGameCategories);
    saveCSV('genres.csv', [...genres.entries()].map(([name, id]) => ({ id, name })));
    saveCSV('game_genres.csv', uniqueGameGenres);
    saveCSV('tags.csv', [...tags.entries()].map(([name, id]) => ({ id, name })));
    saveCSV('game_tags.csv', uniqueGameTags);
    saveCSV('languages.csv', [...languages.entries()].map(([name, id]) => ({ id, name })));
    saveCSV('game_supported_languages.csv', uniqueGameSupportedLanguages);
    saveCSV('game_full_audio_languages.csv', uniqueGameFullAudioLanguages);
    saveCSV('media.csv', uniqueMedia);
  });
