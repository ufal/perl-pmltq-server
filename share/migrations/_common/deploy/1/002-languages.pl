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

    $lang_group_rs->create({
        name => 'Major Languages',
        position => $gpos++,
        languages => [
            { code => 'en', name => 'English', position => $lpos++ },
            { code => 'de', name => 'German', position => $lpos++ },
            { code => 'fr', name => 'French', position => $lpos++ },
            { code => 'es', name => 'Spanish', position => $lpos++ },
            { code => 'it', name => 'Italian', position => $lpos++ },
            { code => 'ru', name => 'Russian', position => $lpos++ },
            { code => 'ar', name => 'Arabic', position => $lpos++ },
            { code => 'zh', name => 'Chinese', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Other Slavic languages',
        position => $gpos++,
        languages => [
            { code => 'cs', name => 'Czech', position => $lpos++ },
            { code => 'sk', name => 'Slovak', position => $lpos++ },
            { code => 'pl', name => 'Polish', position => $lpos++ },
            { code => 'dsb', name => 'Lower Sorbian', position => $lpos++ },
            { code => 'hsb', name => 'Upper Sorbian', position => $lpos++ },
            { code => 'be', name => 'Belarusian', position => $lpos++ },
            { code => 'uk', name => 'Ukrainian', position => $lpos++ },
            { code => 'sl', name => 'Slovene', position => $lpos++ },
            { code => 'hr', name => 'Croatian', position => $lpos++ },
            { code => 'sr', name => 'Serbian', position => $lpos++ },
            { code => 'mk', name => 'Macedonian', position => $lpos++ },
            { code => 'bg', name => 'Bulgarian', position => $lpos++ },
            { code => 'cu', name => 'Old Church Slavonic', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Other Germanic languages',
        position => $gpos++,
        languages => [
            { code => 'nl', name => 'Dutch', position => $lpos++ },
            { code => 'af', name => 'Afrikaans', position => $lpos++ },
            { code => 'fy', name => 'Frisian', position => $lpos++ },
            { code => 'lb', name => 'Luxemburgish', position => $lpos++ },
            { code => 'yi', name => 'Yiddish', position => $lpos++ },
            { code => 'da', name => 'Danish', position => $lpos++ },
            { code => 'sv', name => 'Swedish', position => $lpos++ },
            { code => 'no', name => 'Norwegian', position => $lpos++ },
            { code => 'nn', name => 'Nynorsk (New Norwegian)', position => $lpos++ },
            { code => 'fo', name => 'Faroese', position => $lpos++ },
            { code => 'is', name => 'Icelandic', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Other Romance and Italic languages',
        position => $gpos++,
        languages => [
            { code => 'la', name => 'Latin', position => $lpos++ },
            { code => 'pt', name => 'Portuguese', position => $lpos++ },
            { code => 'gl', name => 'Galician', position => $lpos++ },
            { code => 'ca', name => 'Catalan', position => $lpos++ },
            { code => 'oc', name => 'Occitan', position => $lpos++ },
            { code => 'rm', name => 'Rhaeto-Romance', position => $lpos++ },
            { code => 'co', name => 'Corsican', position => $lpos++ },
            { code => 'sc', name => 'Sardinian', position => $lpos++ },
            { code => 'ro', name => 'Romanian', position => $lpos++ },
            { code => 'mo', name => 'Moldovan (deprecated: use Romanian)', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Celtic languages',
        position => $gpos++,
        languages => [
            { code => 'ga', name => 'Irish', position => $lpos++ },
            { code => 'gd', name => 'Scottish', position => $lpos++ },
            { code => 'cy', name => 'Welsh', position => $lpos++ },
            { code => 'br', name => 'Breton', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Baltic languages',
        position => $gpos++,
        languages => [
            { code => 'lt', name => 'Lithuanian', position => $lpos++ },
            { code => 'lv', name => 'Latvian', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Other Indo-European languages in Europe and Caucasus',
        position => $gpos++,
        languages => [
            { code => 'sq', name => 'Albanian', position => $lpos++ },
            { code => 'el', name => 'Greek', position => $lpos++ },
            { code => 'grc', name => 'Ancient Greek', position => $lpos++ },
            { code => 'hy', name => 'Armenian', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Iranian languages',
        position => $gpos++,
        languages => [
            { code => 'fa', name => 'Persian', position => $lpos++ },
            { code => 'ku', name => 'Kurdish', position => $lpos++ },
            { code => 'os', name => 'Ossetic', position => $lpos++ },
            { code => 'tg', name => 'Tajiki', position => $lpos++ },
            { code => 'ps', name => 'Pashto', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Indo-Aryan languages',
        position => $gpos++,
        languages => [
            { code => 'ks', name => 'Kashmiri', position => $lpos++ },
            { code => 'sd', name => 'Sindhi', position => $lpos++ },
            { code => 'pa', name => 'Punjabi', position => $lpos++ },
            { code => 'ur', name => 'Urdu', position => $lpos++ },
            { code => 'hi', name => 'Hindi', position => $lpos++ },
            { code => 'gu', name => 'Gujarati', position => $lpos++ },
            { code => 'mr', name => 'Marathi', position => $lpos++ },
            { code => 'ne', name => 'Nepali', position => $lpos++ },
            { code => 'or', name => 'Oriya', position => $lpos++ },
            { code => 'bn', name => 'Bengali', position => $lpos++ },
            { code => 'as', name => 'Assamese', position => $lpos++ },
            { code => 'rmy', name => 'Romany', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Other Semitic languages',
        position => $gpos++,
        languages => [
            { code => 'mt', name => 'Maltese', position => $lpos++ },
            { code => 'he', name => 'Hebrew', position => $lpos++ },
            { code => 'am', name => 'Amharic', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Finno-Ugric languages',
        position => $gpos++,
        languages => [
            { code => 'hu', name => 'Hungarian', position => $lpos++ },
            { code => 'fi', name => 'Finnish', position => $lpos++ },
            { code => 'et', name => 'Estonian', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Other European and Caucasian languages',
        position => $gpos++,
        languages => [
            { code => 'eu', name => 'Basque', position => $lpos++ },
            { code => 'ka', name => 'Georgian', position => $lpos++ },
            { code => 'ab', name => 'Abkhaz', position => $lpos++ },
            { code => 'ce', name => 'Chechen', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Turkic languages',
        position => $gpos++,
        languages => [
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
        name => 'Other Altay languages',
        position => $gpos++,
        languages => [
            { code => 'xal', name => 'Kalmyk', position => $lpos++ },
            { code => 'bxr', name => 'Buryat', position => $lpos++ },
            { code => 'mn', name => 'Mongol', position => $lpos++ },
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
        name => 'Sino-Tibetan languages',
        position => $gpos++,
        languages => [
            { code => 'hak', name => 'Hakka', position => $lpos++ },
            { code => 'nan', name => 'Taiwanese', position => $lpos++ },
            { code => 'yue', name => 'Cantonese', position => $lpos++ },
            { code => 'lo', name => 'Lao', position => $lpos++ },
            { code => 'th', name => 'Thai', position => $lpos++ },
            { code => 'my', name => 'Burmese', position => $lpos++ },
            { code => 'bo', name => 'Tibetan', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Austro-Asian languages',
        position => $gpos++,
        languages => [
            { code => 'vi', name => 'Vietnamese', position => $lpos++ },
            { code => 'km', name => 'Khmer', position => $lpos++ },
        ]
    });
    $lpos = 0;
    $lang_group_rs->create({
        name => 'Other languages',
        position => $gpos++,
        languages => [
            { code => 'sw', name => 'Swahili', position => $lpos++ },
            { code => 'eo', name => 'Esperanto', position => $lpos++ },
            { code => 'und', name => 'undetermined/unknown language', position => $lpos++ },
        ]
    });
};
