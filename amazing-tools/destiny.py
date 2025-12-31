#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
天干地支卦象占卜脚本
获取当前时辰信息，求卦象，用ASCII艺术展示
"""

import datetime
import random
import hashlib


class YiJingDivination:
    def __init__(self):
        # 天干
        self.tiangan = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]

        # 地支
        self.dizhi = [
            "子",
            "丑",
            "寅",
            "卯",
            "辰",
            "巳",
            "午",
            "未",
            "申",
            "酉",
            "戌",
            "亥",
        ]

        # 时辰对应
        self.shichen_map = {
            "子": (23, 1),
            "丑": (1, 3),
            "寅": (3, 5),
            "卯": (5, 7),
            "辰": (7, 9),
            "巳": (9, 11),
            "午": (11, 13),
            "未": (13, 15),
            "申": (15, 17),
            "酉": (17, 19),
            "戌": (19, 21),
            "亥": (21, 23),
        }

        # 八卦基本信息
        self.bagua = {
            "乾": {"symbol": "☰", "binary": "111", "nature": "天", "direction": "西北"},
            "坤": {"symbol": "☷", "binary": "000", "nature": "地", "direction": "西南"},
            "震": {"symbol": "☳", "binary": "001", "nature": "雷", "direction": "东"},
            "巽": {"symbol": "☴", "binary": "110", "nature": "风", "direction": "东南"},
            "坎": {"symbol": "☵", "binary": "010", "nature": "水", "direction": "北"},
            "离": {"symbol": "☲", "binary": "101", "nature": "火", "direction": "南"},
            "艮": {"symbol": "☶", "binary": "100", "nature": "山", "direction": "东北"},
            "兑": {"symbol": "☱", "binary": "011", "nature": "泽", "direction": "西"},
        }

        # 64卦卦辞（选取部分经典卦辞）
        self.liushisi_gua = {
"乾乾": {"name": "乾为天", "text": """乾。元，亨，利，贞。
象曰：天行健，君子以自强不息。"""},

"坤坤": {"name": "坤为地", "text": """坤。元，亨，利牝马之贞。君子有攸往，先迷后得主。利西南得朋，东北丧朋。安贞，吉。
象曰：地势坤，君子以厚德载物。"""},

"坎震":{"name": "水雷屯", "text":"""屯。元，亨，利，贞。勿用，有攸往，利建侯。
象曰：云，雷，屯；君子以经纶。"""},

"艮坎":{"name":"山水蒙","text": """蒙。亨。匪我求童蒙，童蒙求我。初筮告，再三渎，渎则不告。利贞。
象曰：山下出泉，蒙。君子以果行育德。"""},

"坎乾":{"name":"水天需","text":"""需。有孚，光亨，贞吉。利涉大川。
象曰：云上于天，需；君子以饮食宴乐。"""},

"乾坎":{"name":"天水讼","text":"""讼。有孚，窒惕，中吉，终凶。利见大人，不利涉大川。
象曰：天与水违行，讼。君子以做事谋始。"""},

"坤坎":{"name":"地水师","text":"""师。贞，丈人吉，无咎。
象曰：地中有水，师。君子以容民畜众。"""},

"坎坤":{"name":"水地比","text":"""比。吉。原筮，元永贞，无咎。不宁方来，后夫凶。
象曰：地上有水，比。先王以建万国，亲诸侯。"""},

"巽乾":{"name":"风天小蓄","text":"""小畜。亨。密云不雨，自我西郊。
象曰：风行天上，小畜。君子以懿文德。"""},

"乾兑":{"name":"天泽履","text":"""履。履虎尾，不咥人，亨。
象曰：上天下泽，履。君子以辨上下，定民志。"""},

"坤乾":{"name":"地天泰","text":"""豫。利建侯行师。
象曰：雷出地奋，豫。先王以作乐崇德，殷荐之上帝，以配祖考。"""},

"乾坤":{"name":"天地否","text":"""否。否之匪人。不利君子贞。大往小来。
象曰：天地不交，否。君子以俭德辟难，不可荣以禄。"""},

"乾离":{"name":"天火同人","text":"""同人。同人于野，亨。利涉大川，利君子贞。
象曰：天与火，同人；君子以类族辨物。"""},

"离乾":{"name":"火天大有","text":"""大有。元亨。
象曰：火在天上，大有。君子以遏恶扬善，顺天休命。"""},

"坤艮":{"name":"地山谦","text":"""谦。亨，君子有终。
象曰：地中有山，谦。君子以裒多益寡，称物平施。"""},

"震坤":{"name":"雷地豫","text":"""豫。利建侯行师。
象曰：雷出地奋，豫。先王以作乐崇德，殷荐之上帝，以配祖考。"""},

"兑震":{"name":"泽雷随","text":"""随。元亨，利贞，无咎。
象曰：泽中有雷，随。君子以向晦入宴息。"""},

"艮巽":{"name":"山风蛊","text":"""蛊。元亨，利涉大川。先甲三日，后甲三日。
象曰：山下有风，蛊。君子以振民育德。"""},

"坤兑":{"name":"地泽临","text":"""临。元，亨，利，贞。至于八月有凶。
象曰：泽上有地，临。君子以教思无穷，客保民无疆。"""},

"巽坤":{"name":"风地观","text":"""观。盥而不荐，有孚顒若。
象曰：风行地上，观。先王以省方，观民设教。"""},

"离震":{"name":"火雷噬嗑","text":"""噬嗑。亨。利用狱。
象曰：雷电噬嗑。先王以明罚敕法。"""},

"艮离":{"name":"山火贲","text":"""贲。亨。小利有攸往。
象曰：山下有火，贲。君子以明庶政，无敢折狱。"""},

"艮坤":{"name":"山地剥","text":"""剥。不利有攸往。
象曰：山附于地，剥。上以厚下，安宅。"""},

"坤震":{"name":"地雷复","text":"""复。亨。出入无疾，朋来无咎。反复其道，七日来复，利有攸往。
象曰：雷在地中，复。先王以至日闭关，商旅不行，后不省方。"""},

"乾震":{"name":"天雷无妄","text":"""无妄。元，亨，利，贞。其匪正有眚，不利有攸往。
象曰：天下雷行，物与无妄。先王以茂对时，育万物。"""},

"艮乾":{"name":"山天大畜","text":"""大畜。利贞，不家食，吉。利涉大川。
象曰：天在山中，大畜。君子以多识前言往行，以畜其德。"""},

"艮震":{"name":"山雷颐","text":"""颐。贞吉。观颐，自求口实。
象曰：山下有雷，颐。君子以慎言语，节饮食。"""},

"兑巽":{"name":"泽风大过","text":"""大过。栋桡。利有攸往，亨。
象曰：泽灭木，大过。君子以独立不惧，遁世无闷。"""},

"坎坎":{"name":"坎为水","text":"""坎。习坎，有孚，维心亨，行有尚。
象曰：水洊至，习坎。君子以常德行，习教事。"""},

"离离":{"name":"离为火","text":"""离。利贞，亨。畜牝牛，吉。
象曰：明两作，离。大人以继明照四方。"""},

"兑艮":{"name":"泽山咸","text":"""咸。亨，利贞。取女吉。
象曰：山上有泽，咸。君子以虚受人。"""},

"震巽":{"name":"雷风恒","text":"""恒。亨，无咎，利贞。利有攸往。
象曰：雷风，恒。君子以立不易方。"""},

"乾艮":{"name":"天山遁","text":"""遁。亨。小利贞。
象曰：天下有山，遁。君子以远小人，不恶而严。"""},

"震乾":{"name":"雷天大壮","text":"""大壮。利贞。
象曰：雷在天上，大壮。君子以非礼弗履。"""},

"离坤":{"name":"火地晋","text":"""晋。康侯用锡马蕃庶，昼日三接。
象曰：明出地上，晋。君子以自昭明德。"""},

"坤离":{"name":"地火明夷","text":"""明夷。利艰贞。
象曰：明入地中，明夷。君子以莅众，用晦而明。"""},

"巽离":{"name":"风火家人","text":"""家人。利女贞。
象曰：风自火出，家人。君子以言有物，而行有恒。"""},

"离兑":{"name":"火泽睽","text":"""睽。小事吉。
象曰：上火下泽，睽。君子以同而异。"""},

"坎艮":{"name":"水山蹇","text":"""蹇。利西南，不利东北。利见大人，贞吉。
象曰：山上有水，蹇。君子以反身修德。"""},

"震坎":{"name":"雷水解","text":"""解。利西南。无所往，其来复吉。有攸往，夙吉。
象曰：雷雨作，解。君子以赦过宥罪。"""},

"艮兑":{"name":"山泽损","text":"""损。有孚，元吉，无咎，可贞。利有攸往。曷之用？二簋可用享。
象曰：山下有泽，损。君子以征忿窒欲。"""},

"巽震":{"name":"风雷益","text":"""益。利有攸往，利涉大川。
象曰：风雷，益。君子以见善则迁，有过则改。"""},

"兑乾":{"name":"泽天夬","text":"""夬。扬于王庭，孚号，有厉。告自邑，不利即戎，利有攸往。
象曰：泽上于天，夬。君子以施禄及下，居德则忌。"""},

"乾巽":{"name":"天风姤","text":"""姤。女壮，勿用取女。
象曰：天下有风，姤。后以施命诰四方。"""},

"兑坤":{"name":"泽地萃","text":"""萃。亨，王假有庙。利见大人，亨，利贞。用大牲吉。利有攸往。
象曰：泽上于地，萃。君子以除戎器，戒不虞。"""},

"坤巽":{"name":"地风升","text":"""升。元亨。用见大人，勿恤，南征吉。
象曰：地中生木，升。君子以顺德，积小以高大。"""},

"兑坎":{"name":"泽水困","text":"""困。亨，贞，大人吉，无咎。有言不信。
象曰：泽无水，困。君子以致命遂志。"""},

"坎巽":{"name":"水风井","text":"""井。改邑不改井，无丧无得。往来井井。汔至，亦未繘井，羸其瓶，凶。
象曰：木上有水，井。君子以劳民劝相。"""},

"兑离":{"name":"泽火革","text":"""革。己日乃孚。元亨利贞。悔亡。
象曰：泽中有火，革。君子以治历明时。"""},

"离巽":{"name":"火风鼎","text":"""鼎。元吉，亨。
象曰：木上有火，鼎。君子以正位凝命。"""},

"震震":{"name":"震为雷","text":"""震。亨。震来虩虩，笑言哑哑。震惊百里，不丧匕鬯。
象曰：洊雷，震。君子以恐惧修省。"""},

"艮艮":{"name":"艮为山","text":"""艮。艮其背，不获其身。行其庭，不见其人。无咎。
象曰：兼山，艮。君子以思不出其位。"""},

"巽艮":{"name":"风山渐","text":"""渐。女归吉，利贞。
象曰：山上有木，渐。君子以居贤德善俗。"""},

"震兑":{"name":"雷泽归妹","text":"""归妹。征凶，无攸利。
象曰：泽上有雷，归妹。君子以永终知敝。"""},

"震离":{"name":"雷火丰","text":"""丰。亨。王假之，勿忧，宜日中。
象曰：雷电皆至，丰。君子以折狱致刑。"""},

"离艮":{"name":"火山旅","text":"""旅。小亨，旅贞吉。
象曰：山上有火，旅。君子以明慎用刑，而不留狱。"""},

"巽巽":{"name":"巽为风","text":"""巽。小亨。利有攸往，利见大人。
象曰：随风，巽。君子以申命行事。"""},

"兑兑":{"name":"兑为泽","text":"""兑。亨，利，贞。
象曰：丽泽，兑。君子以朋友讲习。"""},

"巽坎":{"name":"风水涣","text":"""涣。亨，王假有庙。利涉大川，利贞。
象曰：风行水上，涣。先王以享于帝，立庙。"""},

"坎兑":{"name":"水泽节","text":"""节。亨，苦节不可贞。
象曰：泽上有水，节。君子以制数度，议德行。"""},

"巽兑":{"name":"风泽中孚","text":"""中孚。豚鱼，吉。利涉大川，利贞。
象曰：泽上有风，中孚。君子以议狱缓死。"""},

"震艮":{"name":"雷山小过","text":"""小过。亨，利贞。可小事，不可大事。飞鸟遗之音。不宜上，宜下，大吉。
象曰：山上有雷，小过。君子以行过乎恭，丧过乎衰，用过乎俭。"""},

"坎离":{"name":"水火既济","text":"""既济。亨，小利贞，初吉终乱。
象曰：水在火上，既济。君子以思患而预防之。"""},

"离坎":{"name":"火水未济","text":"""未济。亨，小狐汔济，濡其尾，无攸利。
象曰：火在水上，未济。君子以慎辨物居方。"""}
        }


        # 卦象缓存，防止短时间内重复卜卦
        self._gua_cache = {}
        self._cache_duration = 24 * 60 * 60  # 缓存30分钟（1800秒）

    def get_time_seed(self):
        """获取基于时间的种子，用于确保同一时段内结果相同"""
        now = datetime.datetime.now()
        # 以30分钟为单位生成种子，确保30分钟内卦象相同
        time_unit = now.replace(
            minute=(now.minute // (24 * 60)) * (24 * 60), second=0, microsecond=0
        )
        time_str = time_unit.strftime("%Y%m%d%H%M")
        return hashlib.md5(time_str.encode()).hexdigest()[:8]

    def get_current_ganzhi_time(self):
        """获取当前天干地支时辰信息"""
        now = datetime.datetime.now()
        year = now.year
        month = now.month
        day = now.day
        hour = now.hour

        # 计算年份天干地支（简化算法）
        year_tiangan = self.tiangan[(year - 4) % 10]
        year_dizhi = self.dizhi[(year - 4) % 12]

        # 计算时辰地支
        for shichen, (start_hour, end_hour) in self.shichen_map.items():
            if start_hour <= hour < end_hour or (
                start_hour > end_hour and (hour >= start_hour or hour < end_hour)
            ):
                current_shichen = shichen
                break

        # 计算时辰天干（简化）
        shichen_index = self.dizhi.index(current_shichen)
        shichen_tiangan = self.tiangan[(day * 2 + shichen_index) % 10]

        return {
            "year": f"{year_tiangan}{year_dizhi}年",
            "time": f"{shichen_tiangan}{current_shichen}时",
            "datetime": now.strftime("%Y-%m-%d %H:%M:%S"),
        }

    def divine_gua(self):
        """占卜获取卦象，同一时段内结果相同"""
        time_seed = self.get_time_seed()

        # 检查缓存
        if time_seed in self._gua_cache:
            return self._gua_cache[time_seed]

        # 清理过期缓存
        current_time = datetime.datetime.now()
        expired_keys = []
        for key, (result, timestamp) in self._gua_cache.items():
            if (current_time - timestamp).total_seconds() > self._cache_duration:
                expired_keys.append(key)

        for key in expired_keys:
            del self._gua_cache[key]

        # 使用时间种子设置随机数种子
        random.seed(int(time_seed, 16)+hash(args.bu))

        # 随机选择上下两卦
        shangua = random.choice(list(self.bagua.keys()))
        xiagua = random.choice(list(self.bagua.keys()))

        gua_combination = f"{shangua}{xiagua}"

        # 获取卦辞，如果没有则使用默认
        gua_info = self.liushisi_gua.get(
            gua_combination,
            {
                "name": f"{shangua}上{xiagua}下",
                "text": f"上{self.bagua[shangua]['nature']}下{self.bagua[xiagua]['nature']}，当顺应天时，修身养性",
            },
        )

        result = {
            "shangua": shangua,
            "xiagua": xiagua,
            "shangua_symbol": self.bagua[shangua]["symbol"],
            "xiagua_symbol": self.bagua[xiagua]["symbol"],
            "guaxiang": gua_info["name"],
            "text": gua_info["text"],
        }

        # 缓存结果
        self._gua_cache[time_seed] = (result, current_time)

        return result

    def get_ascii_gua(self, gua_name):
        """获取卦象的ASCII艺术表示"""
        # 八卦的ASCII艺术表示（用线条表示阴阳爻）
        ascii_gua = {
            "乾": [  # 三阳爻 ☰
                "━━━━━━━",
                "━━━━━━━",
                "━━━━━━━",
            ],
            "坤": [  # 三阴爻 ☷
                "━━━ ━━━",
                "━━━ ━━━",
                "━━━ ━━━",
            ],
            "震": [  # 一阳二阴 ☳
                "━━━ ━━━",
                "━━━ ━━━",
                "━━━━━━━",
            ],
            "巽": [  # 二阳一阴 ☴
                "━━━━━━━",
                "━━━━━━━",
                "━━━ ━━━",
            ],
            "坎": [  # 阴阳阴 ☵
                "━━━ ━━━",
                "━━━━━━━",
                "━━━ ━━━",
            ],
            "离": [  # 阳阴阳 ☲
                "━━━━━━━",
                "━━━ ━━━",
                "━━━━━━━",
            ],
            "艮": [  # 阳阴阴 ☶
                "━━━━━━━",
                "━━━ ━━━",
                "━━━ ━━━",
            ],
            "兑": [  # 阴阳阳 ☱
                "━━━ ━━━",
                "━━━━━━━",
                "━━━━━━━",
            ],
        }
        return ascii_gua.get(gua_name, ["Unknown", "Gua", "Symbol"])

    def create_ascii_art(self, gua_result, time_info, show=False):
        """创建ASCII艺术展示"""
        # 获取上下卦的ASCII表示
        shangua_ascii = self.get_ascii_gua(gua_result["shangua"])
        xiagua_ascii = self.get_ascii_gua(gua_result["xiagua"])

        # 爻位说明
        yao_names = (
            ["上爻", "五爻", "四爻", "三爻", "二爻", "初爻"]
            if show
            else ["", "", "", "", "", ""]
        )

        # 构建卦象显示部分
        gua_display = ["┌─────────┐"]
        all_yao = shangua_ascii + xiagua_ascii  # 从上到下：上卦三爻 + 下卦三爻

        for i, line in enumerate(all_yao):
            if i == 3:  # 在上下卦之间添加分隔线
                gua_display.append("├─────────┤")

            yao_type = "阳" if "━━━━━━━" in line else "阴"

            # 在第二爻（索引1）和第五爻（索引4）右侧添加卦名
            if i == 1:  # 上卦第二爻右侧显示上卦名
                if show:
                    comment = f"  ← {yao_names[i]}（{yao_type}）"
                    gua_display.append(f"│ {line} │{gua_result['shangua']}{comment}")
                else:
                    gua_display.append(f"│ {line} │{gua_result['shangua']}")
            elif i == 4:  # 下卦第二爻右侧显示下卦名
                if show:
                    comment = f"  ← {yao_names[i]}（{yao_type}）"
                    gua_display.append(f"│ {line} │{gua_result['xiagua']}{comment}")
                else:
                    gua_display.append(f"│ {line} │{gua_result['xiagua']}")
            else:
                if show:
                    comment = f"  ← {yao_names[i]}（{yao_type}）"
                    gua_display.append(f"│ {line} │{comment}")
                else:
                    gua_display.append(f"│ {line} │")

        gua_display.append("└─────────┘")

        # 构建输出内容（不显示时辰信息）
        content_lines = []

        # 添加卦象显示
        content_lines.extend(gua_display)

        content_lines.append("")

        # # 处理卦辞文本，自动换行
        # wrapped_text = textwrap.fill(gua_result['text'], width=50)
        # content_lines.extend(wrapped_text.split('\n'))

        return "\n".join(content_lines)


def main(args,show=False):
    """主函数"""
    divination = YiJingDivination()

    time_info = divination.get_current_ganzhi_time()
    gua_result = divination.divine_gua()
    ascii_result = divination.create_ascii_art(gua_result, time_info, show)
    print(ascii_result)
    # 返回结果字典
    result = {"guaxiang": gua_result["guaxiang"], "text": gua_result["text"]}
    return result


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--bu", default="", help="占卜内容")
    args = parser.parse_args()
    result = main(args)
    print(result['guaxiang'])
    print()
    print(result['text'])
