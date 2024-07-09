# Script Runner Utility

Ini adalah script bash yang dibuat untuk mempermudah menjalankan script di Virtual Environment secara otomatis. Untuk scriptnya bisa kalian cari di repo developer kepercayaan anda.

[TOC]



## Requirement

- pyenv (Manager Python)
- Python 3.10+
- wmctrl
- php (optional)

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

> You need to place this bash on the same directory as the scripts lies to make this work and make sure you are already setting up the script before using this (See screenshot below)

![Screenshot](<img src="https://i.ibb.co.com/GF7BDQt/Screenshot-2024-07-05-22-27-11.png" alt="Screenshot-2024-07-05-22-27-11" border="0">)

## Note
You need to install the PHP first to run the PHP script

## Todo

- [x] Make a debian package.
- [ ] Setup python scripts inside this.
- [x] Control the window generated.
- [x] Add support for PHP script
- [ ] Add support for JS/Nodejs script
- [ ] Add support for windows
- [ ] Integrate GUI



