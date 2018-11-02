
all: clean proto/user.pb proto/game.pb

proto/user.pb: proto/user.proto
	protoc --descriptor_set_out proto/user.pb proto/user.proto

proto/game.pb: proto/game.proto
	protoc --descriptor_set_out proto/game.pb proto/game.proto

clean:
	rm -f proto/*.pb
