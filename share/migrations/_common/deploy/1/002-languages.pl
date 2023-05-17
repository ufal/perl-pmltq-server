use strict;
use warnings;
use DBIx::Class::Migration::RunScript;


migrate {
    my $db = shift;
    my $lang_group_rs;
    eval {
        $lang_group_rs = $db
            ->schema->resultset("LanguageGroup");
    };
    return if $@; # Skip deployment if table doesn't exists

    my ($gpos, $lpos) = (0, 0);

    $lpos = 0;
    $lang_group_rs->create({
        name => 'Indo-European / Slavic languages',
        position => $gpos++,
        languages => [
            { code => 'cs', name => 'Czech', position => $lpos++ },
            { code => 'sk', name => 'Slovak', position => $lpos++ },
            { code => 'pl', name => 'Polish', position => $lpos++ },
            { code => 'dsb', name => 'Lower Sorbian', position => $lpos++ },
            { code => 'hsb', name => 'Upper Sorbian', position => $lpos++ },
            { code => 'orv', name => 'Old East Slavic', position => $lpos++ },
            { code => 'ru', name => 'Russian', position => $lpos++ },
            { code => 'be', name => 'Belarusian', position => $lpos++ },
            { code => 'uk', name => 'Ukrainian', position => $lpos++ },
            { code => 'sl', name => 'Slovenian', position => $lpos++ },
            { code => 'hr', name => 'Croatian', position => $lpos++ },
            { code => 'bs', name => 'Bosnian', position => $lpos++ },
            { code => 'sr', name => 'Serbian', position => $lpos++ },
            { code => 'mk', name => 'Macedonian', position => $lpos++ },
            { code => 'bg', name => 'Bulgarian', position => $lpos++ },
            { code => 'qpm', name => 'Pomak', position => $lpos++ },
            { code => 'cu', name => 'Old Church Slavonic', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Indo-European / Baltic languages',
        position => $gpos++,
        languages => [
            { code => 'lt', name => 'Lithuanian', position => $lpos++ },
            { code => 'lv', name => 'Latvian', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Indo-European / Germanic languages',
        position => $gpos++,
        languages => [
            { code => 'en', name => 'English', position => $lpos++ },
            { code => 'nl', name => 'Dutch', position => $lpos++ },
            { code => 'af', name => 'Afrikaans', position => $lpos++ },
            { code => 'fy', name => 'Frisian', position => $lpos++ },
            { code => 'nds', name => 'Low Saxon', position => $lpos++ },
            { code => 'lb', name => 'Luxemburgish', position => $lpos++ },
            { code => 'li', name => 'Limburgish', position => $lpos++ },
            { code => 'gsw', name => 'Swiss German and Alsatian', position => $lpos++ },
            { code => 'de', name => 'German', position => $lpos++ },
            { code => 'yi', name => 'Yiddish', position => $lpos++ },
            { code => 'da', name => 'Danish', position => $lpos++ },
            { code => 'sv', name => 'Swedish', position => $lpos++ },
            { code => 'no', name => 'Norwegian', position => $lpos++ },
            { code => 'nn', name => 'Nynorsk (New Norwegian)', position => $lpos++ },
            { code => 'fo', name => 'Faroese', position => $lpos++ },
            { code => 'is', name => 'Icelandic', position => $lpos++ },
            { code => 'got', name => 'Gothic', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Indo-European / Romance languages',
        position => $gpos++,
        languages => [
            { code => 'xum', name => 'Umbrian', position => $lpos++ },
            { code => 'la', name => 'Latin', position => $lpos++ },
            { code => 'it', name => 'Italian', position => $lpos++ },
            { code => 'lij', name => 'Ligurian', position => $lpos++ },
            { code => 'nap', name => 'Neapolitan', position => $lpos++ },
            { code => 'es', name => 'Spanish', position => $lpos++ },
            { code => 'lad', name => 'Ladino', position => $lpos++ },
            { code => 'pt', name => 'Portuguese', position => $lpos++ },
            { code => 'gl', name => 'Galician', position => $lpos++ },
            { code => 'an', name => 'Aragonese', position => $lpos++ },
            { code => 'ca', name => 'Catalan', position => $lpos++ },
            { code => 'oc', name => 'Occitan', position => $lpos++ },
            { code => 'fr', name => 'French', position => $lpos++ },
            { code => 'fro', name => 'Old French', position => $lpos++ },
            { code => 'wa', name => 'Walloon', position => $lpos++ },
            { code => 'rm', name => 'Rhaeto-Romance', position => $lpos++ },
            { code => 'co', name => 'Corsican', position => $lpos++ },
            { code => 'sc', name => 'Sardinian', position => $lpos++ },
            { code => 'ro', name => 'Romanian', position => $lpos++ },
            { code => 'mo', name => 'Moldovan (deprecated: use Romanian)', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Indo-European / Celtic languages',
        position => $gpos++,
        languages => [
            { code => 'pgl', name => 'Archaic Irish', position => $lpos++ },
            { code => 'sga', name => 'Old Irish', position => $lpos++ },
            { code => 'mga', name => 'Middle Irish', position => $lpos++ },
            { code => 'ga', name => 'Irish', position => $lpos++ },
            { code => 'gd', name => 'Scottish (Gaelic)', position => $lpos++ },
            { code => 'gv', name => 'Manx', position => $lpos++ },
            { code => 'kw', name => 'Cornish', position => $lpos++ },
            { code => 'cy', name => 'Welsh', position => $lpos++ },
            { code => 'br', name => 'Breton', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Indo-European / Iranian languages',
        position => $gpos++,
        languages => [
            { code => 'ku', name => 'Kurdish', position => $lpos++ },
            { code => 'kmr', name => 'Kurmanji (Northern Kurdish)', position => $lpos++ },
            { code => 'ckb', name => 'Sorani (Central Kurdish)', position => $lpos++ },
            { code => 'kfm', name => 'Khunsari', position => $lpos++ },
            { code => 'nyq', name => 'Nayini', position => $lpos++ },
            { code => 'soj', name => 'Soi', position => $lpos++ },
            { code => 'os', name => 'Ossetic', position => $lpos++ },
            { code => 'ae', name => 'Avestan', position => $lpos++ },
            { code => 'fa', name => 'Persian', position => $lpos++ },
            { code => 'tg', name => 'Tajiki', position => $lpos++ },
            { code => 'ps', name => 'Pashto', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Indo-European / Dardic and Indo-Aryan languages',
        position => $gpos++,
        languages => [
            { code => 'ks', name => 'Kashmiri', position => $lpos++ },
            { code => 'sa', name => 'Sanskrit', position => $lpos++ },
            { code => 'pi', name => 'Pali', position => $lpos++ },
            { code => 'sd', name => 'Sindhi', position => $lpos++ },
            { code => 'pa', name => 'Punjabi', position => $lpos++ },
            { code => 'ur', name => 'Urdu', position => $lpos++ },
            { code => 'hi', name => 'Hindi', position => $lpos++ },
            { code => 'bh', name => 'Bihari', position => $lpos++ },
            { code => 'bho', name => 'Bhojpuri', position => $lpos++ },
            { code => 'xnr', name => 'Kangri', position => $lpos++ },
            { code => 'ne', name => 'Nepali', position => $lpos++ },
            { code => 'or', name => 'Oriya', position => $lpos++ },
            { code => 'bn', name => 'Bengali', position => $lpos++ },
            { code => 'as', name => 'Assamese', position => $lpos++ },
            { code => 'gu', name => 'Gujarati', position => $lpos++ },
            { code => 'mr', name => 'Marathi', position => $lpos++ },
            { code => 'si', name => 'Sinhala', position => $lpos++ },
            { code => 'dv', name => 'Divehi', position => $lpos++ },
            { code => 'rmy', name => 'Romany', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Indo-European / other languages',
        position => $gpos++,
        languages => [
            { code => 'sq', name => 'Albanian', position => $lpos++ },
            { code => 'aln', name => 'Gheg', position => $lpos++ },
            { code => 'el', name => 'Greek', position => $lpos++ },
            { code => 'pnt', name => 'Pontic', position => $lpos++ },
            { code => 'grc', name => 'Ancient Greek', position => $lpos++ },
            { code => 'hit', name => 'Hittite', position => $lpos++ },
            { code => 'hy', name => 'Armenian', position => $lpos++ },
            { code => 'hyw', name => 'Western Armenian', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Afro-Asiatic languages',
        position => $gpos++,
        languages => [
            { code => 'akk', name => 'Akkadian', position => $lpos++ },
            { code => 'aii', name => 'Assyrian', position => $lpos++ },
            { code => 'ar', name => 'Arabic', position => $lpos++ },
            { code => 'ajp', name => 'South Levantine Arabic', position => $lpos++ },
            { code => 'arz', name => 'Egyptian Arabic', position => $lpos++ },
            { code => 'arq', name => 'Algerian Arabic', position => $lpos++ },
            { code => 'mt', name => 'Maltese', position => $lpos++ },
            { code => 'hbo', name => 'Ancient Hebrew', position => $lpos++ },
            { code => 'he', name => 'Hebrew', position => $lpos++ },
            { code => 'am', name => 'Amharic', position => $lpos++ },
            { code => 'ti', name => 'Tigrinya', position => $lpos++ },
            { code => 'aa', name => 'Afar', position => $lpos++ },
            { code => 'om', name => 'Oromo', position => $lpos++ },
            { code => 'so', name => 'Somali', position => $lpos++ },
            { code => 'bej', name => 'Beja', position => $lpos++ },
            { code => 'egy', name => 'Egyptian', position => $lpos++ },
            { code => 'cop', name => 'Coptic', position => $lpos++ },
            { code => 'ha', name => 'Hausa', position => $lpos++ },
            { code => 'say', name => 'Zaar', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Nilo-Saharan languages',
        position => $gpos++,
        languages => [
            { code => 'kr', name => 'Kanuri', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Niger-Congo languages',
        position => $gpos++,
        languages => [
            { code => 'ff', name => 'Fulah / Fulbe', position => $lpos++ },
            { code => 'wo', name => 'Wolof', position => $lpos++ },
            { code => 'bm', name => 'Bambara', position => $lpos++ },
            { code => 'tw', name => 'Twi (Akan)', position => $lpos++ },
            { code => 'ee', name => 'Ewe', position => $lpos++ },
            { code => 'yo', name => 'Yoruba', position => $lpos++ },
            { code => 'ig', name => 'Igbo', position => $lpos++ },
            { code => 'sg', name => 'Sango', position => $lpos++ },
            { code => 'ln', name => 'Ngala', position => $lpos++ },
            { code => 'rw', name => 'Rwanda', position => $lpos++ },
            { code => 'rn', name => 'Rundi', position => $lpos++ },
            { code => 'lg', name => 'Ganda', position => $lpos++ },
            { code => 'cgg', name => 'Kiga', position => $lpos++ },
            { code => 'nyn', name => 'Nkore', position => $lpos++ },
            { code => 'ki', name => 'Kikuyu', position => $lpos++ },
            { code => 'sw', name => 'Swahili', position => $lpos++ },
            { code => 'kg', name => 'Kongo', position => $lpos++ },
            { code => 'lu', name => 'Luba-Katanga', position => $lpos++ },
            { code => 'ny', name => 'Chichewa (Nyanja)', position => $lpos++ },
            { code => 'ndg', name => 'Ndengeleko', position => $lpos++ },
            { code => 'kj', name => 'Kuanyama', position => $lpos++ },
            { code => 'ng', name => 'Ndonga (Owambo)', position => $lpos++ },
            { code => 'hz', name => 'Herero', position => $lpos++ },
            { code => 'sn', name => 'Shona', position => $lpos++ },
            { code => 've', name => 'Venda', position => $lpos++ },
            { code => 'tn', name => 'Tswana', position => $lpos++ },
            { code => 'st', name => 'Southern Sotho', position => $lpos++ },
            { code => 'xh', name => 'Xhosa', position => $lpos++ },
            { code => 'zu', name => 'Zulu', position => $lpos++ },
            { code => 'ss', name => 'Swati', position => $lpos++ },
            { code => 'nd', name => 'North Ndebele', position => $lpos++ },
            { code => 'nr', name => 'South Ndebele', position => $lpos++ },
            { code => 'ts', name => 'Tsonga', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Khoe-Kwadi languages',
        position => $gpos++,
        languages => [
            { code => 'naq', name => 'Khoekhoe', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Uralic languages',
        position => $gpos++,
        languages => [
            { code => 'hu', name => 'Hungarian', position => $lpos++ },
            { code => 'fi', name => 'Finnish', position => $lpos++ },
            { code => 'krl', name => 'Karelian', position => $lpos++ },
            { code => 'olo', name => 'Livvi', position => $lpos++ },
            { code => 'et', name => 'Estonian', position => $lpos++ },
            { code => 'kv', name => 'Komi', position => $lpos++ },
            { code => 'koi', name => 'Komi Permyak', position => $lpos++ },
            { code => 'kpv', name => 'Komi Zyrian', position => $lpos++ },
            { code => 'myv', name => 'Erzya', position => $lpos++ },
            { code => 'mdf', name => 'Moksha', position => $lpos++ },
            { code => 'se', name => 'Sami', position => $lpos++ },
            { code => 'sme', name => 'Northern Sami', position => $lpos++ },
            { code => 'sms', name => 'Skolt Sami', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'European language isolates',
        position => $gpos++,
        languages => [
            { code => 'eu', name => 'Basque', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Northwest Caucasian languages',
        position => $gpos++,
        languages => [
            { code => 'ab', name => 'Abkhaz', position => $lpos++ },
            { code => 'abq', name => 'Abaza', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Kartvelian languages',
        position => $gpos++,
        languages => [
            { code => 'ka', name => 'Georgian', position => $lpos++ },
            { code => 'lzz', name => 'Laz', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Northeast Caucasian languages',
        position => $gpos++,
        languages => [
            { code => 'ce', name => 'Chechen', position => $lpos++ },
            { code => 'inh', name => 'Ingush', position => $lpos++ },
            { code => 'av', name => 'Avar', position => $lpos++ },
            { code => 'dar', name => 'Dargwa', position => $lpos++ },
            { code => 'lbe', name => 'Lak', position => $lpos++ },
            { code => 'lez', name => 'Lezgian', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Turkic languages',
        position => $gpos++,
        languages => [
            { code => 'otk', name => 'Old Turkish', position => $lpos++ },
            { code => 'tr', name => 'Turkish', position => $lpos++ },
            { code => 'az', name => 'Azeri', position => $lpos++ },
            { code => 'cv', name => 'Chuvash', position => $lpos++ },
            { code => 'ba', name => 'Bashkir', position => $lpos++ },
            { code => 'tt', name => 'Tatar', position => $lpos++ },
            { code => 'tk', name => 'Turkmen', position => $lpos++ },
            { code => 'uz', name => 'Uzbek', position => $lpos++ },
            { code => 'kaa', name => 'Karakalpak', position => $lpos++ },
            { code => 'kk', name => 'Kazakh', position => $lpos++ },
            { code => 'ky', name => 'Kyrgyz', position => $lpos++ },
            { code => 'ug', name => 'Uyghur', position => $lpos++ },
            { code => 'sah', name => 'Yakut', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Altaic languages',
        position => $gpos++,
        languages => [
            { code => 'xal', name => 'Kalmyk', position => $lpos++ },
            { code => 'bxr', name => 'Buryat', position => $lpos++ },
            { code => 'mn', name => 'Mongol', position => $lpos++ },
            { code => 'sjo', name => 'Xibe', position => $lpos++ },
            { code => 'ko', name => 'Korean', position => $lpos++ },
            { code => 'ja', name => 'Japanese', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Dravidian languages',
        position => $gpos++,
        languages => [
            { code => 'te', name => 'Telugu', position => $lpos++ },
            { code => 'kn', name => 'Kannada', position => $lpos++ },
            { code => 'ml', name => 'Malayalam', position => $lpos++ },
            { code => 'ta', name => 'Tamil', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Tai-Kadai languages',
        position => $gpos++,
        languages => [
            { code => 'th', name => 'Thai', position => $lpos++ },
            { code => 'lo', name => 'Lao', position => $lpos++ },
            { code => 'shn', name => 'Shan', position => $lpos++ },
            { code => 'zu', name => 'Zhuang', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Sino-Tibetan languages',
        position => $gpos++,
        languages => [
            { code => 'lzh', name => 'Classical Chinese', position => $lpos++ },
            { code => 'zh', name => 'Chinese', position => $lpos++ },
            { code => 'hak', name => 'Hakka', position => $lpos++ },
            { code => 'nan', name => 'Taiwanese', position => $lpos++ },
            { code => 'yue', name => 'Cantonese', position => $lpos++ },
            { code => 'ii', name => 'Yi', position => $lpos++ },
            { code => 'my', name => 'Burmese', position => $lpos++ },
            { code => 'bo', name => 'Tibetan', position => $lpos++ },
            { code => 'dz', name => 'Dzongkha', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Austro-Asian languages',
        position => $gpos++,
        languages => [
            { code => 'vi', name => 'Vietnamese', position => $lpos++ },
            { code => 'km', name => 'Khmer', position => $lpos++ },
            { code => 'pbv', name => 'Pnar', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Austronesian languages',
        position => $gpos++,
        languages => [
            { code => 'mg', name => 'Malagasy', position => $lpos++ },
            { code => 'ms', name => 'Malay', position => $lpos++ },
            { code => 'id', name => 'Indonesian', position => $lpos++ },
            { code => 'jv', name => 'Javanese', position => $lpos++ },
            { code => 'su', name => 'Sundanese', position => $lpos++ },
            { code => 'ch', name => 'Chamorro', position => $lpos++ },
            { code => 'ifb', name => 'Batad Ifugao', position => $lpos++ },
            { code => 'tl', name => 'Tagalog', position => $lpos++ },
            { code => 'ilo', name => 'Ilocano', position => $lpos++ },
            { code => 'ceb', name => 'Cebuano', position => $lpos++ },
            { code => 'hil', name => 'Hiligaynon', position => $lpos++ },
            { code => 'na', name => 'Nauruan', position => $lpos++ },
            { code => 'mh', name => 'Marshallese', position => $lpos++ },
            { code => 'ho', name => 'Hiri Motu', position => $lpos++ },
            { code => 'fj', name => 'Fijian', position => $lpos++ },
            { code => 'to', name => 'Tongan', position => $lpos++ },
            { code => 'sm', name => 'Samoan', position => $lpos++ },
            { code => 'mi', name => 'Maori', position => $lpos++ },
            { code => 'ty', name => 'Tahitian', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Pama-Nyungan languages',
        position => $gpos++,
        languages => [
            { code => 'dbl', name => 'Dyirbal', position => $lpos++ },
            { code => 'wbp', name => 'Warlpiri', position => $lpos++ },
            { code => 'yii', name => 'Yidiny', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Chukotko-Kamchatkan languages',
        position => $gpos++,
        languages => [
            { code => 'ckt', name => 'Chukchi', position => $lpos++ },
            { code => 'kpy', name => 'Koryak', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Eskimo-Aleut languages',
        position => $gpos++,
        languages => [
            { code => 'ess', name => 'Central Siberian Yupik', position => $lpos++ },
            { code => 'esu', name => 'Central Alaskan Yupik', position => $lpos++ },
            { code => 'ems', name => 'Alutiiq', position => $lpos++ },
            { code => 'ik', name => 'Inupiaq', position => $lpos++ },
            { code => 'iu', name => 'Inuit', position => $lpos++ },
            { code => 'kl', name => 'Greenlandic', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Algic languages',
        position => $gpos++,
        languages => [
            { code => 'cr', name => 'Cree', position => $lpos++ },
            { code => 'oj', name => 'Ojibwe', position => $lpos++ },
            { code => 'arp', name => 'Arapaho', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Na-Dene languages',
        position => $gpos++,
        languages => [
            { code => 'scs', name => 'North Slavey', position => $lpos++ },
            { code => 'xsl', name => 'South Slavey', position => $lpos++ },
            { code => 'nv', name => 'Navajo', position => $lpos++ },
            { code => 'apw', name => 'Western Apache', position => $lpos++ },
            { code => 'apm', name => 'Mescalero-Chiricahua', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Uto-Aztecan languages',
        position => $gpos++,
        languages => [
            { code => 'hop', name => 'Hopi', position => $lpos++ },
            { code => 'nah', name => 'Nahuatl', position => $lpos++ },
            { code => 'nhi', name => 'Western Sierra Puebla Nahuatl', position => $lpos++ },
            { code => 'tar', name => 'Tarahumara', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Mayan languages',
        position => $gpos++,
        languages => [
            { code => 'quc', name => 'Kiche', position => $lpos++ },
            { code => 'yua', name => 'Yucatec Maya', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Arawakan languages',
        position => $gpos++,
        languages => [
            { code => 'apu', name => 'Apurina', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Arawan languages',
        position => $gpos++,
        languages => [
            { code => 'jaa', name => 'Madi', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Quechuan and Aymaran languages',
        position => $gpos++,
        languages => [
            { code => 'qu', name => 'Quechua', position => $lpos++ },
            { code => 'quz', name => 'Cusco Quechua', position => $lpos++ },
            { code => 'ay', name => 'Aymara', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Panoan languages',
        position => $gpos++,
        languages => [
            { code => 'shp', name => 'Shipibo-Konibo', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Macro-Je languages',
        position => $gpos++,
        languages => [
            { code => 'xav', name => 'Xavante', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Bororoan languages',
        position => $gpos++,
        languages => [
            { code => 'bor', name => 'Bororo', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Tupian languages',
        position => $gpos++,
        languages => [
            { code => 'aqz', name => 'Akuntsu', position => $lpos++ },
            { code => 'myu', name => 'Munduruku', position => $lpos++ },
            { code => 'tpn', name => 'Tupinamba', position => $lpos++ },
            { code => 'yrl', name => 'Nheengatu', position => $lpos++ },
            { code => 'gub', name => 'Guajajara', position => $lpos++ },
            { code => 'gn', name => 'Guarani', position => $lpos++ },
            { code => 'gun', name => 'Mbya Guarani', position => $lpos++ },
            { code => 'mpu', name => 'Makurap', position => $lpos++ },
            { code => 'urb', name => 'Kaapor', position => $lpos++ },
            { code => 'arr', name => 'Karo', position => $lpos++ },
            { code => 'eme', name => 'Teko', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Creole languages',
        position => $gpos++,
        languages => [
            { code => 'ht', name => 'Haitian', position => $lpos++ },
            { code => 'bi', name => 'Bislama', position => $lpos++ },
            { code => 'pcm', name => 'Nigerian Pidgin (Naija)', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Other languages',
        position => $gpos++,
        languages => [
            { code => 'eo', name => 'Esperanto', position => $lpos++ },
            { code => 'ia', name => 'Interlingua', position => $lpos++ },
            { code => 'ie', name => 'Interlingue', position => $lpos++ },
            { code => 'io', name => 'Ido', position => $lpos++ },
            { code => 'vo', name => 'Volapuk', position => $lpos++ },
            { code => 'swl', name => 'Swedish Sign Language', position => $lpos++ },
            { code => 'qhe', name => 'Hindi-English code-switching', position => $lpos++ },
            { code => 'qaf', name => 'Maghrebi Arabic-French code-switching', position => $lpos++ },
            { code => 'qtd', name => 'Turkish-German code-switching', position => $lpos++ },
            { code => 'qfn', name => 'Frisian-Dutch code-switching', position => $lpos++ },
            { code => 'und', name => 'undetermined/unknown language', position => $lpos++ },
        ]
    });
};
