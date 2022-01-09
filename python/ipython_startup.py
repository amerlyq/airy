#%USAGE: ~/.ipython/profile_default/startup/
#%SEIZE: https://towardsdatascience.com/how-to-automatically-import-your-favorite-libraries-into-ipython-or-a-jupyter-notebook-9c69d89aa343
# pylint:disable=unused-import
import os
import os.path as fs
import re
import sys
from pathlib import Path

from just.ext.datetime.alias import DD, DT, TH, TM, TT
from just.ext.datetime.cvt import dt_hmx

# ALT: /__import__("just.iji.util").iji.util.print_ret <expr>
from just.ext.print import print_ret as p
