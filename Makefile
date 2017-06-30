builddir="build/"

Hasklock: init
	ghc src/Main.hs -odir build -o bin/Hasklock
	chmod +x bin/randhasklock

init:
	mkdir -p $(builddir)

clean:
	rm -rf $(builddir)

install: 
	install -Dm755 bin/Hasklock /bin/hasklock
	install -Dm755 bin/randhasklock /bin/randhasklock
