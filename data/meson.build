i18n.merge_file(
    input: 'datetime.metainfo.xml.in',
    output: gettext_name + '.metainfo.xml',
    po_dir: meson.project_source_root() / 'po' /  'extra',
    type: 'xml',
    install: true,
    install_dir: get_option('datadir') / 'metainfo',
)

install_data(
    'datetime.gschema.xml',
    install_dir: get_option('datadir') / 'glib-2.0' / 'schemas',
    rename: gettext_name + '.gschema.xml'
)
