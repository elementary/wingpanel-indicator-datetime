i18n.merge_file(
    input: 'datetime.metainfo.xml.in',
    output: 'io.elementary.wingpanel.datetime.metainfo.xml',
    po_dir: meson.source_root() / 'po' /  'extra',
    type: 'xml',
    install: true,
    install_dir: get_option('datadir') / 'metainfo',
)

install_data(
    'io.elementary.desktop.wingpanel.datetime.gschema.xml',
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)
