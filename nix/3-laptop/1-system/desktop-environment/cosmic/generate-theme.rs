// Halon for COSMIC, as cosmic-settings would build it.
//
// COSMIC derives a whole theme from a handful of builder colours, so this runs that derivation over Halon's tokens and writes the result into
// ./theme, where the module beside it installs it as the system default. Run it against libcosmic rev d922ac3 with XDG_CONFIG_HOME pointed at a
// scratch directory, then copy the cosmic/ tree it writes over ./theme.

use cosmic_config::CosmicConfigEntry;
use cosmic_theme::{CornerRadii, Theme, ThemeBuilder};
use palette::{Srgb, Srgba};

/// Turns a 0xRRGGBB literal into the sRGB triple the builder wants.
fn rgb(hex: u32) -> Srgb {
    Srgb::new(
        ((hex >> 16) & 0xff) as f32 / 255.0,
        ((hex >> 8) & 0xff) as f32 / 255.0,
        (hex & 0xff) as f32 / 255.0,
    )
}

/// The same, opaque, for the surface colours that carry an alpha channel.
fn rgba(hex: u32) -> Srgba {
    let c = rgb(hex);
    Srgba::new(c.red, c.green, c.blue, 1.0)
}

/// Halon's radius ladder: 4 for small controls, 6 for list rows, 8 for buttons and cards, 10 for windows, and a pill.
fn radii() -> CornerRadii {
    CornerRadii {
        radius_0: [0.0; 4],
        radius_xs: [4.0; 4],
        radius_s: [6.0; 4],
        radius_m: [8.0; 4],
        radius_l: [10.0; 4],
        radius_xl: [160.0; 4],
    }
}

/// Writes both schemes and the builders they came from.
fn main() {
    let mut light_builder = ThemeBuilder::light()
        .corner_radii(radii())
        .bg_color(rgba(0xf1f5f9))
        .primary_container_bg(rgba(0xffffff))
        .neutral_tint(rgb(0x64748b))
        .text_tint(rgb(0x0f172a))
        .accent(rgb(0x2563eb))
        .success(rgb(0x047857))
        .warning(rgb(0xf59e0b))
        .destructive(rgb(0xdc2626));
    light_builder.secondary_container_bg = Some(rgba(0xf1f5f9));

    let mut dark_builder = ThemeBuilder::dark()
        .corner_radii(radii())
        .bg_color(rgba(0x060b14))
        .primary_container_bg(rgba(0x16213a))
        .neutral_tint(rgb(0x94a3b8))
        .text_tint(rgb(0xf8fafc))
        .accent(rgb(0x60a5fa))
        .success(rgb(0x10b981))
        .warning(rgb(0xf59e0b))
        .destructive(rgb(0xf87171));
    dark_builder.secondary_container_bg = Some(rgba(0x060b14));

    let mut light = light_builder.clone().build();
    light.name = "Halon".to_string();
    light.write_entry(&Theme::light_config().unwrap()).unwrap();

    let mut dark = dark_builder.clone().build();
    dark.name = "Halon Dark".to_string();
    dark.write_entry(&Theme::dark_config().unwrap()).unwrap();
    light_builder
        .write_entry(&ThemeBuilder::light_config().unwrap())
        .unwrap();
    dark_builder
        .write_entry(&ThemeBuilder::dark_config().unwrap())
        .unwrap();
    println!("written");
}
