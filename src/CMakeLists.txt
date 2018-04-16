find_package (PkgConfig)

# Add all your dependencies to the list below
pkg_check_modules (DEPS REQUIRED gthread-2.0 gtk+-3.0 wingpanel-2.0 granite
  libecal-1.2 libical libsoup-2.4 libedataserver-1.2)

add_definitions (${DEPS_CFLAGS})
link_directories (${DEPS_LIBRARY_DIRS})

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.40.3" MINIMUM)

include (ValaPrecompile)
# Add all your vala files and requires packages to the List below to include them in the build
vala_precompile (VALA_C ${CMAKE_PROJECT_NAME}
  Indicator.vala
  Widgets/PanelLabel.vala
  Widgets/calendar/Calendar.vala
  Widgets/calendar/CalendarModel.vala
  Widgets/calendar/CalendarView.vala
  Widgets/calendar/ControlHeader.vala
  Widgets/calendar/Util.vala
  Widgets/calendar/Grid.vala
  Widgets/calendar/GridDay.vala
  Widgets/calendar/Header.vala
  Widgets/calendar/WeekLabels.vala
  Services/TimeManager.vala
  Services/ClockSettings.vala
  Services/SettingsManager.vala
  ${CMAKE_CURRENT_BINARY_DIR}/config.vala
PACKAGES
  wingpanel-2.0
  glib-2.0>=2.32
  granite
  libecalendar-1.2
  libedataserver-1.2
  libical
  libsoup-2.4
OPTIONS
  --target-glib=2.32
  --vapidir=${CMAKE_SOURCE_DIR}/vapi
  --thread
)

add_library (${CMAKE_PROJECT_NAME} MODULE ${VALA_C})
target_link_libraries(${CMAKE_PROJECT_NAME} ${DEPS_LIBRARIES})

# Installation
install (TARGETS ${CMAKE_PROJECT_NAME} DESTINATION ${PKGDATADIR})
