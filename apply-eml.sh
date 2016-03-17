#!/bin/sh

sed -n '/^From:/, $p' $1
