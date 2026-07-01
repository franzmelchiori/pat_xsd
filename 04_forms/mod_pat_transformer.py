"""
    PAT XML transformer
    ⌘ 2026 Francesco Melchiori
"""


from lxml import etree


XML_to_trasform_PATH = './04_forms/mod_comunicazione_inizio_lavori_sue_20260612_part.xml'
XSLT_PATH = './04_forms/mod_comunicazione_inizio_lavori_v1.0.8_part.xslt'


def prettyprint(element, **kwargs):
    xml = etree.tostring(element, pretty_print=True, **kwargs)
    print(xml.decode(), end='')
    print('')


if __name__ == '__main__':

    ## XML to transform
    parser_xml = etree.XMLParser(remove_blank_text=True)
    tree_xml = etree.parse(XML_to_trasform_PATH, parser_xml)
    root_xml = tree_xml.getroot()

    if False:
        prettyprint(tree_xml)

    ## XSLT
    parser_xslt = etree.XMLParser(remove_blank_text=True)
    tree_xslt = etree.parse(XSLT_PATH, parser_xslt)
    transform_xslt = etree.XSLT(tree_xslt)

    ## XML transformed
    result_tree_xml = transform_xslt(root_xml)

    if True:
        prettyprint(result_tree_xml)
