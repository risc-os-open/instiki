# Contains all the methods for finding and replacing wiki words
#
class WikiWords
  # In order of appearance: Latin, greek, cyrillic, armenian
  I18N_HIGHER_CASE_LETTERS =
    "ÀÁÂÃÄÅĀĄĂÆÇĆČĈĊĎĐÈÉÊËĒĘĚĔĖĜĞĠĢĤĦÌÍÎÏĪĨĬĮİĲĴĶŁĽĹĻĿÑŃŇŅŊÒÓÔÕÖØŌŐŎŒŔŘŖŚŠŞŜȘŤŢŦȚÙÚÛÜŪŮŰŬŨŲŴŶŸȲÝŹŽŻ" +
    "ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ" +
    "ЀЁЂЃЄЅІЇЈЉЊЋЌЍЎЏАБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯѠѢѤѦѨѪѬѮѰѲѴѶѸѺѼѾҀҊҌҎҐҒҔҖҘҚҜҞҠҢҤҦҨҪҬҮҰҲҴҶҸҺҼҾӀӁӃӅӇӉӋӍӐӒӔӖӘӚӜӞӠӢӤӦӨӪӬӮӰӲӴӶӸӺӼӾԀԂԄԆԈԊԌԎԐԒԔԖԘԚԜԞԠԢ" +
    "ԱԲԳԴԵԶԷԸԹԺԻԼԽԾԿՀՁՂՃՄՅՆՇՈՉՊՋՌՍՎՏՐՑՒՓՔՕՖ"

  I18N_LOWER_CASE_LETTERS =
    "àáâãäåāąăæçćĉċčďđèéêëēęěĕėƒĝğġģĥħìíîïīĩĭįıĳĵķĸłľĺļŀñńňņŉŋòóôõöøōŏőœŕřŗśŝšşșťţŧțùúûüūůűŭũųŵýÿŷžżźÞþßſð" +
    "άέήίΰαβγδεζηθικλμνξοπρςστυφχψωϊϋόύώΐ" +
    "абвгдежзийклмнопрстуфхцчшщъыьэюяѐёђѓєѕіїјљњћќѝўџѡѣѥѧѩѫѭѯѱѳѵѷѹѻѽѿҁҋҍҏґғҕҗҙқҝҟҡңҥҧҩҫҭүұҳҵҷҹһҽҿӂӄӆӈӊӌӎӏӑӓӕӗәӛӝӟӡӣӥӧөӫӭӯӱӳӵӷӹӻӽӿԁԃԅԇԉԋԍԏԑԓԕԗԙԛԝԟԡԣ" +
     "աբգդեզէըթժիլխծկհձղճմյնշոչպջռսվտրցւփքօֆև"

  WIKI_WORD_PATTERN = '[A-Z' + I18N_HIGHER_CASE_LETTERS + ']+[a-z' + I18N_LOWER_CASE_LETTERS + ']+[A-Z' + I18N_HIGHER_CASE_LETTERS +
    '][A-Za-z0-9_' + I18N_HIGHER_CASE_LETTERS +  I18N_LOWER_CASE_LETTERS + ']+'
  CAMEL_CASED_WORD_BORDER = /([a-z#{I18N_LOWER_CASE_LETTERS}])([A-Z#{I18N_HIGHER_CASE_LETTERS}])/u

  def self.separate(wiki_word)

    # 2011-03-13 (ADH): The ROOL Wiki only supports [[these]] links as allowing
    #                   CamelCase would fall foul of numerous non-link cases in
    #                   its technical content. Accordingly, when the Wiki shows
    #                   titles for missing pages and so forth, we *don't* want
    #                   it to mungle the title. Really, Instiki probably ought
    #                   to disable this according to the relevant Web setting
    #                   but it doesn't pass that information down to here.
    #
    # wiki_word.dup.as_utf8.gsub(CAMEL_CASED_WORD_BORDER, '\1 \2')

    return wiki_word.dup.as_utf8
  end
end
