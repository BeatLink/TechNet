from textual.theme import Theme

white_blue_theme = Theme(
    name="white_blue",
    primary="#00ACFF",
    secondary="#00ACFF",
    accent="#B48EAD",
    foreground="#D8DEE9",
    background="#001B29",
    success="#00FF00",
    warning="#EBCB8B",
    error="#FF0000",
    surface="#001B29",
    panel="#434C5E",
    dark=True,
    variables={    
        "block-cursor-text-style": "none",
        "footer-key-foreground": "#88C0D0",
        "input-selection-background": "#81a1c1 35%",
    },
)
