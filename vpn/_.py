from just.airy.spec import AiryMod

if 'm' not in globals():
    m = AiryMod()

m.pkgs.append("openconnect")

m.aurs.append("vpn-slice")
