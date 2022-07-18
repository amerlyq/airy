rule = {
  matches = {
    {
      { "node.nick", "matches", "HDMI" }
    },
  },
  apply_properties = {
    ["node.disabled"] = true,
  },
}

table.insert(alsa_monitor.rules, rule)
