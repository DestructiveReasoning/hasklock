all:
	ghc Main.hs -o Hasklock

install:
	install -Dm755 Hasklock /bin/hasklock
	install -Dm755 randhasklock /bin/randhasklock
