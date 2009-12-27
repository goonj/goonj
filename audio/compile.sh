g++ -framework CoreAudio \
	-framework AudioUnit \
	-framework Carbon \
	-lavformat -lavutil -lavcodec \
	-lz -lm -lbz2 \
	main.cpp RenderSin.cpp RenderSin.h
