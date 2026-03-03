## Hooks daemon for ai aigents

Very simple unix style dispatch for hooks for agents. It should be somewhat generic but also file system based it should install a router that listens for hook events and forwards to downsteam scripts.
providing an order mechanism by filename and termination control. It should be able to display a graph of hooks.

The interesting part is probably understanding the hook piece and configuration for multiple coding agents. I could see this as a bash script but it might also be better as just some compiled binary.
This would make it more OS portable aside from the build issues, while I love crystal this would be a good reason to make it go. Before we start we should research if this already exists and if there are simpler alternatives.
