/*
 *
 *  Attract-Mode frontend
 *  Copyright (C) 2013-15 Andrew Mickelson
 *
 *  This file is part of Attract-Mode.
 *
 *  Attract-Mode is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Attract-Mode is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Attract-Mode.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#ifndef FE_SETTINGS_HPP
#define FE_SETTINGS_HPP

#include "fe_base.hpp"
#include "fe_info.hpp"
#include "fe_romlist.hpp"
#include "fe_input.hpp"

extern const char *FE_ART_EXTENSIONS[];

extern const char *FE_CFG_FILE;

extern const char *FE_ROMLIST_SUBDIR;
extern const char *FE_SCRAPER_SUBDIR;
extern const char *FE_LAYOUT_FILE_BASE;
extern const char *FE_LAYOUT_FILE_EXTENSION;

extern const char *FE_CFG_YES_STR;
extern const char *FE_CFG_NO_STR;

class FeImporterContext;

// A container for each task when importing/building romlists from the command line
class FeImportTask
{
public:

	enum TaskType
	{
		BuildRomlist,
		ImportRomlist,
		ScrapeArtwork
	};

	FeImportTask( TaskType t, const std::string &en, const std::string &fn="" )
		: task_type( t ), emulator_name( en ), file_name( fn )
	{
	};

	TaskType task_type;
	std::string emulator_name;
	std::string file_name;
};

class FeSettings : public FeBaseConfigurable
{
public:
   enum RotationState { RotateNone=0, RotateRight, RotateFlip, RotateLeft };

	enum WindowType { Default=0, Fullscreen, Window };
	static const char *windowModeTokens[];
	static const char *windowModeDispTokens[];

	enum FilterWrapModeType { WrapWithinDisplay=0, JumpToNextDisplay, NoWrap };
	static const char *filterWrapTokens[];
	static const char *filterWrapDispTokens[];

	enum ConfigSettingIndex
	{
		Language=0,
		ExitCommand,
		DefaultFont,
		FontPath,
		ScreenSaverTimeout,
		DisplaysMenuExit,
		HideBrackets,
		AutoLaunchLastGame,
		ConfirmFavourites,
		MouseThreshold,
		JoystickThreshold,
		WindowMode,
		FilterWrapMode,
		TrackUsage,
		SmoothImages,
		AccelerateSelection,
		SelectionSpeed,
		ScrapeSnaps,
		ScrapeMarquees,
		ScrapeFlyers,
		ScrapeWheels,
		ScrapeFanArt,
		LAST_INDEX
	};

	static const char *configSettingStrings[];
	static const char *otherSettingStrings[];

private:
	std::string m_config_path;
	std::string m_default_font;
	std::string m_exit_command;
	std::string m_language;

	std::vector<std::string> m_font_paths;
	std::vector<FeDisplayInfo> m_displays;
	std::vector<FePlugInfo> m_plugins;
	std::vector<FeLayoutInfo> m_layout_params;
	FeRomList m_rl;

	FeInputMap m_inputmap;
	FeSoundInfo m_sounds;
	FeResourceMap m_resourcemap;
	FeLayoutInfo m_saver_params;
	sf::IntRect m_mousecap_rect;

	int m_current_display;
	FeBaseConfigurable *m_current_config_object;
	int m_ssaver_time;
	int m_last_launch_display;
	int m_last_launch_filter;
	int m_last_launch_rom;
	int m_joy_thresh;		// [1..100], 100=least sensitive
	int m_mouse_thresh;	// [1..100], 100=least sensitive
	bool m_displays_menu_exit;
	bool m_hide_brackets;
	bool m_autolaunch_last_game;
	bool m_confirm_favs;
	bool m_track_usage;
	WindowType m_window_mode;
	bool m_smooth_images;
	FilterWrapModeType m_filter_wrap_mode;
	bool m_accel_selection;
	int m_selection_speed;
	bool m_scrape_snaps;
	bool m_scrape_marquees;
	bool m_scrape_flyers;
	bool m_scrape_wheels;
	bool m_scrape_fanart;

	FeSettings( const FeSettings & );
	FeSettings &operator=( const FeSettings & );

	int process_setting( const std::string &,
						const std::string &,
						const std::string & );

	void init_display();
	void load_state();
	void clear();

	void internal_gather_config_files(
			std::vector<std::string> &ll,
			const std::string &extension,
			const char *subdir ) const;

	void internal_load_language( const std::string &lang );

	bool mamedb_scraper( FeImporterContext & );
	bool thegamesdb_scraper( FeImporterContext & );
	void apply_xml_import( FeImporterContext & );


public:
	FeSettings( const std::string &config_dir,
				const std::string &cmdln_font );

	void load();
	void save_state();

	FeInputMap::Command map_input( const sf::Event &e );
	FeInputMap::Command map_input( const ManyMouseEvent &e );
	bool config_map_input( const sf::Event &e, std::string &s, FeInputMap::Command &conflict );
	bool config_map_input( const ManyMouseEvent &e, std::string &s, FeInputMap::Command &conflict );

	bool get_current_state( FeInputMap::Command c );
	void get_input_mappings( std::vector < FeMapping > &l ) const { m_inputmap.get_mappings( l ); };
	void set_input_mapping( FeMapping &m ) { m_inputmap.set_mapping( m ); };

	void set_volume( FeSoundInfo::SoundType, const std::string & );
	int get_set_volume( FeSoundInfo::SoundType ) const;
	int get_play_volume( FeSoundInfo::SoundType ) const;
	bool get_mute() const;
	void set_mute( bool );
	bool get_sound_file( FeInputMap::Command, std::string &s, bool full_path=true ) const;
	void set_sound_file( FeInputMap::Command, const std::string &s );
	void get_sounds_list( std::vector < std::string > &ll ) const;

	void step_current_selection( int step );
	void set_current_selection( int filter_index, int rom_index ); // use rom_index<0 to only change the filter

	// Switches the display
	// returns true if the display change results in a new layout, false otherwise
	//
	bool set_display( int index );
	int get_current_display_index() const;
	int get_display_index_from_name( const std::string &name ) const;
	int displays_count() const;

	bool navigate_display( int step, bool wrap_mode=false );
	bool navigate_filter( int step );

	int get_current_filter_index() const;
	const std::string &get_filter_name( int filter_index );
	void get_current_display_filter_names( std::vector<std::string> &list ) const;
	int get_filter_index_from_offset( int offset ) const;
	int get_filter_size( int filter_index ) const;
	int get_filter_count() const;

	bool select_last_launch();
	int get_joy_thresh() const { return m_joy_thresh; }
	int get_mouse_thresh() const { return m_mouse_thresh; }
	void init_mouse_capture( int window_x, int window_y );
	bool test_mouse_reset( int mouse_x, int mouse_y ) const;

	void run( int &minimum_run_seconds ); // run current selection
	int exit_command() const; // run configured exit command (if any)

	void toggle_layout();
	void set_current_layout_file( const std::string &layout_file );

	int get_rom_index( int filter_index, int offset ) const;

	void do_text_substitutions( std::string &str, int filter_offset, int index_offset );
	void do_text_substitutions_absolute( std::string &str, int filter_index, int rom_index );

	void get_current_sort( FeRomInfo::Index &idx, bool &rev, int &limit );

	const std::string &get_current_display_title() const;
	const std::string &get_rom_info( int filter_offset, int rom_offset, FeRomInfo::Index index );
	const std::string &get_rom_info_absolute( int filter_index, int rom_index, FeRomInfo::Index index );
	FeRomInfo *get_rom_absolute( int filter_index, int rom_index );

	int selection_speed() const { return m_selection_speed; }

	// get a list of available plugins
	void get_available_plugins( std::vector < std::string > &list ) const;
	std::vector<FePlugInfo> &get_plugins() { return m_plugins; }
	FePlugInfo *get_plugin( const std::string &label );
	bool get_plugin_enabled( const std::string &label ) const;
	void get_plugin_full_path( const std::string &label,
			std::string &path,
			std::string &filename ) const;

	void get_script_loader_file( std::string &path, std::string &filename ) const;
	void get_screensaver_file( std::string &path, std::string &filename ) const;
	FeLayoutInfo &get_screensaver_config() { return m_saver_params; }
	std::string get_current_layout_file() const;
	std::string get_current_layout_dir() const;
	std::string get_layout_dir( const std::string &layout_name ) const;
	void get_layouts_list( std::vector<std::string> &layouts ) const;
	FeLayoutInfo &get_layout_config( const std::string &layout_name );
	FeLayoutInfo &get_current_layout_config();

	bool get_best_artwork_file(
		const FeRomInfo &rom,
		const std::string &art_name,
		std::vector<std::string> &vid_list,
		std::vector<std::string> &image_list,
		bool is_screen_saver,
		bool ignore_layout );

	bool has_artwork( const FeRomInfo &rom, const std::string &art_name );

	bool get_best_dynamic_image_file(
		int filter_index,
		int rom_index,
		const std::string &logo_str,
		std::vector<std::string> &vid_list,
		std::vector<std::string> &image_list,
		bool is_screen_saver );

	std::string get_module_dir( const std::string &module_file ) const;

	const std::string &get_config_dir() const;
	bool config_file_exists() const;
	bool get_font_file( std::string &fullpath, const std::string &filename="" ) const;

	WindowType get_window_mode() const;
	FilterWrapModeType get_filter_wrap_mode() const;
	int get_screen_saver_timeout() const;

	bool get_current_fav() const;

	// returns true if the current list chnaged as a result of setting the tag
	bool set_current_fav( bool );
	int get_prev_fav_offset() const;
	int get_next_fav_offset() const;

	int get_next_letter_offset( int step ) const;

	void get_current_tags_list(
		std::vector< std::pair<std::string, bool> > &tags_list ) const;

	// returns true if the current list changed as a result of setting the tag
	bool set_current_tag(
			const std::string &tag, bool flag );
	//
	// This function implements command-line romlist generation/imports
	// If output_name is empty, then a non-existing filename is chosen for
	// the resulting romlist file
	//
	bool build_romlist( const std::vector< FeImportTask > &task_list,
							const std::string &output_name,
							FeFilter &filter,
							bool full );

	// This function implements the config-mode romlist generation
	// A romlist named "<emu_name>.txt" is created in the romlist dir,
	// overwriting any previous list of this name.
	//
	typedef bool (*UiUpdate) ( void *, int );
	bool build_romlist( const std::string &emu_name, UiUpdate, void *, int & );
	bool scrape_artwork( const std::string &emu_name, UiUpdate uiu, void *uid, std::string &msg );

	FeEmulatorInfo *get_emulator( const std::string & );
	FeEmulatorInfo *create_emulator( const std::string & );
	void delete_emulator( const std::string & );

	//
	// Functions used for configuration
	//
	const std::string get_info( int index ) const; // see "ConfigSettingIndex"
	bool get_info_bool( int index ) const;
	bool set_info( int index, const std::string & );

	void get_display_names( std::vector<std::string> &d ) const;
	FeDisplayInfo *get_display( int index );
	FeDisplayInfo *create_display( const std::string &n );
	void delete_display( int index );

	void create_filter( FeDisplayInfo &l, const std::string &name ) const;

	// return true if specified romlist name is configured for use as a display
	// list
	bool check_romlist_configured( const std::string &n ) const;
	void get_romlists_list( std::vector < std::string > &ll ) const;

	void save() const;

	void get_resource( const std::string &token, std::string &str ) const;
	void get_resource( const std::string &token, const std::string &rep,
									std::string &str ) const;

	void set_language( const std::string &s );
	const std::string &get_language() const { return m_language; }
	void get_languages_list( std::vector < std::string > &ll ) const;

	// Utility function to get a list of layout*.nut files from the specified path...
	static void get_layout_file_basenames_from_path(
								const std::string &path,
								std::vector<std::string> &names_list );
};

#endif
