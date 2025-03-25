# SandyXpc

SandyXpc is an easy-to-use XPC library for modern jailbreaks that eliminates the need for **RocketBootstrap**.

Supports rootless or roothide jailbreaks, iOS 15 and later.

## Installation

```bash
git clone https://github.com/Lessica/SandyXpc.git
cd SandyXpc
make clean stage  # <-- this installs SandyXpc to $THEOS
```

## Usage

SandyXpc uses `NSXPCConnection` to communicate between processes. It doesn’t inject into a middle man process like _MobileGestaltHelper_. You have to use [**libSandy**](https://github.com/opa334/libSandy/) to bypass the sandbox if needed.

`SandyXpcMessagingCenter` is similar in API to `CPDistributedMessagingCenter`.

For more information, see [`examples`](./examples/).
