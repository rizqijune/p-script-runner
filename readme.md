# Python Script Runner Utility

Ini adalah script bash yang dibuat untuk mempermudah menjalankan script python di Virtual Environment secara otomatis. Untuk script pythonnya bisa kalian cari di repo github developer kepercayaan anda.

[TOC]



## Requirement

- pyenv (Manager Python)
- Python 3.10+
- wmctrl

## How to use

#### Setup

1. Create virtual environment `pyenv virtualenv telebots`
2. Activate venv `pyenv activate telebots`
3. Install requirements `pip install -r requirements.txt`
4. Make it executable `chmod +x /path/to/your/auto.sh`
5. Execute file in working folder `./auto.sh`
6. Follow the instructions.

#### Run

Just run `./auto.sh` in the working directory if you already set this up.

> You need to place this bash on the same directory as the python scripts lies to make this work and make sure you are already setting up the python script before using this (See screenshot below)

## Todo

- [ ] Make a debian package.
- [ ] Setup python scripts inside this.
- [x] Control the window generated.
- [ ] Integrate GUI



