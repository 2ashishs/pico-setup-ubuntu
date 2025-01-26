# Pico SDK Setup Script

This is a modified version of Pico SDK Setup script for Ubuntu x86_64, tested on Ubuntu 24.10. VS Code dependencies have been removed.

`pico_setup.sh` script
 - is run in `bash` shell.

`pico_setup.zsh` script
 - is run in `zsh` shell.
 - allows you to create skeleton projects for different `Pico` variants using the alias `picox`.

`picox` usage examples:
```shell
# create a project named OledServer for Pico-2W
picox OledServer 2w

# create a project named OledBlink for Pico-2
picox OledBlink 2

# create a project named BlinkServer for Pico-W
picox BlinkServer w

# create a project named DiscoLights for Pico
picox DiscoLights
```

To build a project say `DiscoLights`:
```shell
cd DiscoLights
# Update your code and then
./do
```
This will build your project, creating the `build` directory, which will contain the executable `.uf2` file.
