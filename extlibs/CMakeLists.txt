if(NOT NO_MOVIE)
	add_subdirectory(audio)
endif()

add_subdirectory(squirrel)

if(NOT EXPAT_FOUND)
	add_subdirectory(expat)
endif()

if(NOT NO_SWF)
	add_subdirectory(gameswf)
endif()
