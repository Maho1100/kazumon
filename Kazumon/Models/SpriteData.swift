import Foundation

// MARK: - スプライトフレーム定義（Kenney Monster Characters）
struct SpriteFrame {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
}

let SPRITESHEET_SIZE: CGFloat = 1480

let spriteFrames: [String: SpriteFrame] = [

    // ── Bodies ──

    "body_blueA":    SpriteFrame(x: 366,  y: 472,  width: 165, height: 165),
    "body_blueB":    SpriteFrame(x: 0,    y: 192,  width: 192, height: 192),
    "body_blueC":    SpriteFrame(x: 677,  y: 0,    width: 141, height: 194),
    "body_blueD":    SpriteFrame(x: 192,  y: 546,  width: 174, height: 182),
    "body_blueE":    SpriteFrame(x: 683,  y: 1190, width: 132, height: 250),
    "body_blueF":    SpriteFrame(x: 366,  y: 0,    width: 170, height: 236),

    "body_darkA":    SpriteFrame(x: 531,  y: 472,  width: 165, height: 165),
    "body_darkB":    SpriteFrame(x: 0,    y: 0,    width: 192, height: 192),
    "body_darkC":    SpriteFrame(x: 677,  y: 194,  width: 141, height: 194),
    "body_darkD":    SpriteFrame(x: 192,  y: 182,  width: 174, height: 182),
    "body_darkE":    SpriteFrame(x: 697,  y: 388,  width: 132, height: 250),
    "body_darkF":    SpriteFrame(x: 348,  y: 1200, width: 170, height: 236),

    "body_greenA":   SpriteFrame(x: 518,  y: 1129, width: 165, height: 165),
    "body_greenB":   SpriteFrame(x: 0,    y: 768,  width: 192, height: 192),
    "body_greenC":   SpriteFrame(x: 536,  y: 194,  width: 141, height: 194),
    "body_greenD":   SpriteFrame(x: 192,  y: 0,    width: 174, height: 182),
    "body_greenE":   SpriteFrame(x: 824,  y: 888,  width: 132, height: 250),
    "body_greenF":   SpriteFrame(x: 366,  y: 236,  width: 170, height: 236),

    "body_redA":     SpriteFrame(x: 518,  y: 964,  width: 165, height: 165),
    "body_redB":     SpriteFrame(x: 0,    y: 960,  width: 192, height: 192),
    "body_redC":     SpriteFrame(x: 536,  y: 0,    width: 141, height: 194),
    "body_redD":     SpriteFrame(x: 0,    y: 1152, width: 174, height: 182),
    "body_redE":     SpriteFrame(x: 818,  y: 0,    width: 132, height: 250),
    "body_redF":     SpriteFrame(x: 192,  y: 728,  width: 170, height: 236),

    "body_whiteA":   SpriteFrame(x: 518,  y: 1294, width: 165, height: 165),
    "body_whiteB":   SpriteFrame(x: 0,    y: 384,  width: 192, height: 192),
    "body_whiteC":   SpriteFrame(x: 683,  y: 996,  width: 141, height: 194),
    "body_whiteD":   SpriteFrame(x: 192,  y: 364,  width: 174, height: 182),
    "body_whiteE":   SpriteFrame(x: 815,  y: 1190, width: 132, height: 250),
    "body_whiteF":   SpriteFrame(x: 362,  y: 728,  width: 170, height: 236),

    "body_yellowA":  SpriteFrame(x: 532,  y: 637,  width: 165, height: 165),
    "body_yellowB":  SpriteFrame(x: 0,    y: 576,  width: 192, height: 192),
    "body_yellowC":  SpriteFrame(x: 683,  y: 802,  width: 141, height: 194),
    "body_yellowD":  SpriteFrame(x: 174,  y: 1152, width: 174, height: 182),
    "body_yellowE":  SpriteFrame(x: 824,  y: 638,  width: 132, height: 250),
    "body_yellowF":  SpriteFrame(x: 348,  y: 964,  width: 170, height: 236),

    // ── Eyes ──

    "eye_angry_blue":      SpriteFrame(x: 438,  y: 637,  width: 64, height: 58),
    "eye_angry_green":     SpriteFrame(x: 697,  y: 747,  width: 60, height: 55),
    "eye_angry_red":       SpriteFrame(x: 757,  y: 747,  width: 60, height: 55),
    "eye_blue":            SpriteFrame(x: 950,  y: 181,  width: 64, height: 69),
    "eye_closed_feminine": SpriteFrame(x: 432,  y: 1436, width: 50, height: 18),
    "eye_closed_happy":    SpriteFrame(x: 306,  y: 1334, width: 42, height: 18),
    "eye_cute_dark":       SpriteFrame(x: 536,  y: 388,  width: 64, height: 69),
    "eye_cute_light":      SpriteFrame(x: 1026, y: 1410, width: 64, height: 69),
    "eye_dead":            SpriteFrame(x: 310,  y: 1115, width: 32, height: 32),
    "eye_human":           SpriteFrame(x: 1090, y: 1410, width: 64, height: 69),
    "eye_human_blue":      SpriteFrame(x: 600,  y: 388,  width: 64, height: 69),
    "eye_human_green":     SpriteFrame(x: 1283, y: 393,  width: 64, height: 69),
    "eye_human_red":       SpriteFrame(x: 1048, y: 927,  width: 64, height: 69),
    "eye_psycho_dark":     SpriteFrame(x: 1283, y: 462,  width: 64, height: 69),
    "eye_psycho_light":    SpriteFrame(x: 1154, y: 1410, width: 64, height: 69),
    "eye_red":             SpriteFrame(x: 1218, y: 1422, width: 64, height: 58),
    "eye_yellow":          SpriteFrame(x: 1216, y: 1002, width: 64, height: 69),

    // ── Eyebrows ──

    "eyebrowA": SpriteFrame(x: 634, y: 802,  width: 49, height: 32),
    "eyebrowB": SpriteFrame(x: 380, y: 1436, width: 52, height: 33),
    "eyebrowC": SpriteFrame(x: 428, y: 695,  width: 57, height: 33),

    // ── Mouths ──

    "mouth_closed_happy": SpriteFrame(x: 0,   y: 1443, width: 80, height: 24),
    "mouth_closed_fangs": SpriteFrame(x: 258, y: 1115, width: 52, height: 20),
    "mouth_closed_sad":   SpriteFrame(x: 432, y: 1459, width: 52, height: 20),
    "mouth_closed_teeth": SpriteFrame(x: 220, y: 1443, width: 66, height: 26),
    "mouthA": SpriteFrame(x: 80,  y: 1443, width: 70, height: 34),
    "mouthB": SpriteFrame(x: 150, y: 1443, width: 70, height: 34),
    "mouthC": SpriteFrame(x: 192, y: 1073, width: 78, height: 38),
    "mouthD": SpriteFrame(x: 192, y: 1115, width: 66, height: 27),
    "mouthE": SpriteFrame(x: 366, y: 685,  width: 62, height: 39),
    "mouthF": SpriteFrame(x: 306, y: 1436, width: 74, height: 42),
    "mouthG": SpriteFrame(x: 586, y: 911,  width: 50, height: 44),
    "mouthH": SpriteFrame(x: 824, y: 1138, width: 78, height: 52),
    "mouthI": SpriteFrame(x: 270, y: 1073, width: 74, height: 42),
    "mouthJ": SpriteFrame(x: 366, y: 637,  width: 72, height: 48),

    // ── Arms ──

    "arm_blueA":    SpriteFrame(x: 1117, y: 176,  width: 82,  height: 176),
    "arm_blueB":    SpriteFrame(x: 1402, y: 274,  width: 51,  height: 161),
    "arm_blueC":    SpriteFrame(x: 927,  y: 431,  width: 98,  height: 181),
    "arm_blueD":    SpriteFrame(x: 956,  y: 612,  width: 92,  height: 197),
    "arm_blueE":    SpriteFrame(x: 1216, y: 853,  width: 71,  height: 149),

    "arm_darkA":    SpriteFrame(x: 1117, y: 352,  width: 82,  height: 176),
    "arm_darkB":    SpriteFrame(x: 1399, y: 498,  width: 51,  height: 161),
    "arm_darkC":    SpriteFrame(x: 829,  y: 431,  width: 98,  height: 181),
    "arm_darkD":    SpriteFrame(x: 1045, y: 1006, width: 92,  height: 197),
    "arm_darkE":    SpriteFrame(x: 1281, y: 1002, width: 71,  height: 149),

    "arm_greenA":   SpriteFrame(x: 1130, y: 528,  width: 82,  height: 176),
    "arm_greenB":   SpriteFrame(x: 1400, y: 836,  width: 51,  height: 161),
    "arm_greenC":   SpriteFrame(x: 950,  y: 0,    width: 98,  height: 181),
    "arm_greenD":   SpriteFrame(x: 1025, y: 181,  width: 92,  height: 197),
    "arm_greenE":   SpriteFrame(x: 1281, y: 1273, width: 71,  height: 149),

    "arm_redA":     SpriteFrame(x: 1048, y: 751,  width: 82,  height: 176),
    "arm_redB":     SpriteFrame(x: 1406, y: 659,  width: 51,  height: 161),
    "arm_redC":     SpriteFrame(x: 829,  y: 250,  width: 98,  height: 181),
    "arm_redD":     SpriteFrame(x: 1025, y: 378,  width: 92,  height: 197),
    "arm_redE":     SpriteFrame(x: 1209, y: 704,  width: 71,  height: 149),

    "arm_whiteA":   SpriteFrame(x: 1048, y: 0,    width: 82,  height: 176),
    "arm_whiteB":   SpriteFrame(x: 1390, y: 1298, width: 51,  height: 161),
    "arm_whiteC":   SpriteFrame(x: 947,  y: 1138, width: 98,  height: 181),
    "arm_whiteD":   SpriteFrame(x: 1045, y: 1203, width: 92,  height: 197),
    "arm_whiteE":   SpriteFrame(x: 1271, y: 244,  width: 71,  height: 149),

    "arm_yellowA":  SpriteFrame(x: 1048, y: 575,  width: 82,  height: 176),
    "arm_yellowB":  SpriteFrame(x: 1400, y: 113,  width: 51,  height: 161),
    "arm_yellowC":  SpriteFrame(x: 927,  y: 250,  width: 98,  height: 181),
    "arm_yellowD":  SpriteFrame(x: 956,  y: 809,  width: 92,  height: 197),
    "arm_yellowE":  SpriteFrame(x: 1280, y: 702,  width: 71,  height: 149),

    // ── Legs ──

    "leg_blueA":    SpriteFrame(x: 1199, y: 124,  width: 72,  height: 167),
    "leg_blueB":    SpriteFrame(x: 1351, y: 687,  width: 55,  height: 149),
    "leg_blueC":    SpriteFrame(x: 1130, y: 828,  width: 79,  height: 124),
    "leg_blueD":    SpriteFrame(x: 1209, y: 0,    width: 71,  height: 122),
    "leg_blueE":    SpriteFrame(x: 204,  y: 1334, width: 102, height: 109),

    "leg_darkA":    SpriteFrame(x: 1209, y: 1243, width: 72,  height: 167),
    "leg_darkB":    SpriteFrame(x: 1347, y: 349,  width: 55,  height: 149),
    "leg_darkC":    SpriteFrame(x: 1137, y: 952,  width: 79,  height: 124),
    "leg_darkD":    SpriteFrame(x: 1212, y: 458,  width: 71,  height: 122),
    "leg_darkE":    SpriteFrame(x: 532,  y: 802,  width: 102, height: 109),

    "leg_greenA":   SpriteFrame(x: 1137, y: 1243, width: 72,  height: 167),
    "leg_greenB":   SpriteFrame(x: 1342, y: 200,  width: 55,  height: 149),
    "leg_greenC":   SpriteFrame(x: 1130, y: 0,    width: 79,  height: 124),
    "leg_greenD":   SpriteFrame(x: 1281, y: 1151, width: 71,  height: 122),
    "leg_greenE":   SpriteFrame(x: 697,  y: 638,  width: 102, height: 109),

    "leg_redA":     SpriteFrame(x: 1137, y: 1076, width: 72,  height: 167),
    "leg_redB":     SpriteFrame(x: 1345, y: 851,  width: 55,  height: 149),
    "leg_redC":     SpriteFrame(x: 956,  y: 1006, width: 79,  height: 124),
    "leg_redD":     SpriteFrame(x: 1271, y: 122,  width: 71,  height: 122),
    "leg_redE":     SpriteFrame(x: 102,  y: 1334, width: 102, height: 109),

    "leg_whiteA":   SpriteFrame(x: 1209, y: 1076, width: 72,  height: 167),
    "leg_whiteB":   SpriteFrame(x: 1352, y: 1000, width: 55,  height: 149),
    "leg_whiteC":   SpriteFrame(x: 1130, y: 704,  width: 79,  height: 124),
    "leg_whiteD":   SpriteFrame(x: 1280, y: 0,    width: 71,  height: 122),
    "leg_whiteE":   SpriteFrame(x: 192,  y: 964,  width: 102, height: 109),

    "leg_yellowA":  SpriteFrame(x: 1199, y: 291,  width: 72,  height: 167),
    "leg_yellowB":  SpriteFrame(x: 1352, y: 1149, width: 55,  height: 149),
    "leg_yellowC":  SpriteFrame(x: 947,  y: 1319, width: 79,  height: 124),
    "leg_yellowD":  SpriteFrame(x: 1212, y: 580,  width: 71,  height: 122),
    "leg_yellowE":  SpriteFrame(x: 0,    y: 1334, width: 102, height: 109),

    // ── Details（角・アンテナ・耳・目玉） ──

    "detail_none":                 SpriteFrame(x: 0, y: 0, width: 1, height: 1),
    "detail_blue_horn_large":      SpriteFrame(x: 1404, y: 54,   width: 40, height: 42),
    "detail_blue_horn_small":      SpriteFrame(x: 664,  y: 415,  width: 31, height: 27),
    "detail_blue_antenna_large":   SpriteFrame(x: 1352, y: 1298, width: 38, height: 58),
    "detail_blue_antenna_small":   SpriteFrame(x: 1442, y: 435,  width: 26, height: 42),
    "detail_blue_ear":             SpriteFrame(x: 1407, y: 1055, width: 38, height: 44),
    "detail_blue_ear_round":       SpriteFrame(x: 1282, y: 1422, width: 54, height: 54),
    "detail_blue_eye":             SpriteFrame(x: 1287, y: 851,  width: 58, height: 78),

    "detail_dark_horn_large":      SpriteFrame(x: 1402, y: 435,  width: 40, height: 42),
    "detail_dark_horn_small":      SpriteFrame(x: 485,  y: 695,  width: 31, height: 27),
    "detail_dark_antenna_large":   SpriteFrame(x: 1352, y: 1356, width: 38, height: 58),
    "detail_dark_antenna_small":   SpriteFrame(x: 1170, y: 124,  width: 26, height: 42),
    "detail_dark_ear":             SpriteFrame(x: 1405, y: 0,    width: 38, height: 44),
    "detail_dark_ear_round":       SpriteFrame(x: 294,  y: 1018, width: 54, height: 54),
    "detail_dark_eye":             SpriteFrame(x: 1342, y: 122,  width: 58, height: 78),

    "detail_green_horn_large":     SpriteFrame(x: 1130, y: 124,  width: 40, height: 42),
    "detail_green_horn_small":     SpriteFrame(x: 664,  y: 388,  width: 31, height: 27),
    "detail_green_antenna_large":  SpriteFrame(x: 1407, y: 997,  width: 38, height: 58),
    "detail_green_antenna_small":  SpriteFrame(x: 502,  y: 637,  width: 26, height: 42),
    "detail_green_ear":            SpriteFrame(x: 1407, y: 1201, width: 38, height: 44),
    "detail_green_ear_round":      SpriteFrame(x: 1336, y: 1422, width: 54, height: 54),
    "detail_green_eye":            SpriteFrame(x: 1283, y: 531,  width: 58, height: 78),

    "detail_red_horn_large":       SpriteFrame(x: 306,  y: 1352, width: 40, height: 42),
    "detail_red_horn_small":       SpriteFrame(x: 636,  y: 923,  width: 31, height: 27),
    "detail_red_antenna_large":    SpriteFrame(x: 1407, y: 1143, width: 38, height: 58),
    "detail_red_antenna_small":    SpriteFrame(x: 1443, y: 0,    width: 26, height: 42),
    "detail_red_ear":              SpriteFrame(x: 1407, y: 1099, width: 38, height: 44),
    "detail_red_ear_round":        SpriteFrame(x: 1287, y: 929,  width: 54, height: 54),
    "detail_red_eye":              SpriteFrame(x: 1283, y: 609,  width: 58, height: 78),

    "detail_white_horn_large":     SpriteFrame(x: 902,  y: 1138, width: 40, height: 42),
    "detail_white_horn_small":     SpriteFrame(x: 664,  y: 442,  width: 31, height: 27),
    "detail_white_antenna_large":  SpriteFrame(x: 1441, y: 1245, width: 38, height: 58),
    "detail_white_antenna_small":  SpriteFrame(x: 1444, y: 42,   width: 26, height: 42),
    "detail_white_ear":            SpriteFrame(x: 1441, y: 1405, width: 38, height: 44),
    "detail_white_ear_round":      SpriteFrame(x: 294,  y: 964,  width: 54, height: 54),
    "detail_white_eye":            SpriteFrame(x: 1341, y: 531,  width: 58, height: 78),

    "detail_yellow_horn_large":    SpriteFrame(x: 306,  y: 1394, width: 40, height: 42),
    "detail_yellow_horn_small":    SpriteFrame(x: 484,  y: 1436, width: 31, height: 27),
    "detail_yellow_antenna_large": SpriteFrame(x: 1441, y: 1303, width: 38, height: 58),
    "detail_yellow_antenna_small": SpriteFrame(x: 1407, y: 1245, width: 26, height: 42),
    "detail_yellow_ear":           SpriteFrame(x: 1441, y: 1361, width: 38, height: 44),
    "detail_yellow_ear_round":     SpriteFrame(x: 1351, y: 0,    width: 54, height: 54),
    "detail_yellow_eye":           SpriteFrame(x: 1341, y: 609,  width: 58, height: 78),

    // ── Noses ──

    "nose_brown":  SpriteFrame(x: 532,  y: 911, width: 54, height: 48),
    "nose_green":  SpriteFrame(x: 1351, y: 54,  width: 53, height: 59),
    "nose_red":    SpriteFrame(x: 636,  y: 834, width: 47, height: 51),
    "nose_yellow": SpriteFrame(x: 636,  y: 885, width: 46, height: 38),

    // ── Extras ──

    "snot_large": SpriteFrame(x: 799, y: 682, width: 18, height: 61),
    "snot_small": SpriteFrame(x: 799, y: 638, width: 21, height: 44),
]
