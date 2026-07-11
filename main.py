import database as db
from datetime import date

from kivy.core.text import LabelBase

from kivymd.app import MDApp
from kivymd.uix.bottomnavigation import MDBottomNavigation, MDBottomNavigationItem
from kivymd.uix.card import MDCard
from kivymd.uix.textfield import MDTextField
from kivymd.uix.button import MDRaisedButton, MDFlatButton, MDIconButton
from kivymd.uix.dialog import MDDialog
from kivymd.uix.label import MDLabel
from kivymd.uix.toolbar import MDTopAppBar
from kivymd.uix.snackbar import Snackbar
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.scrollview import ScrollView
from kivy.uix.gridlayout import GridLayout
from kivy.uix.togglebutton import ToggleButton
from kivy.uix.widget import Widget
from kivy.clock import Clock
from kivy.metrics import dp
import platform
import os

# --- Platform-aware font setup ---
if platform.system() == 'Windows':
    FONT = 'C:/Windows/Fonts/simhei.ttf'
else:
    _CJK = ['/system/fonts/NotoSansCJK-Regular.ttc',
            '/system/fonts/NotoSansSC-Regular.otf',
            '/system/fonts/DroidSansFallback.ttf']
    FONT = 'Roboto'
    for _p in _CJK:
        if os.path.exists(_p):
            FONT = _p
            break
LabelBase.register(name='Roboto', fn_regular=FONT)
# ---

GREEN = (0.18, 0.49, 0.20, 1)
GREEN_LT = (0.26, 0.63, 0.28, 1)
RED = (0.90, 0.22, 0.21, 1)


class TxItem(BoxLayout):
    def __init__(self, tx_id=0, **kw):
        super().__init__(**kw)
        self.tx_id = tx_id
        self.orientation = 'horizontal'
        self.size_hint_y = None
        self.height = dp(52)
        self.padding = [dp(16), 0]

        def ml(txt, sz, **k):
            return MDLabel(text=txt, font_name=FONT, **k)
        def ib(ic, **k):
            return MDIconButton(icon=ic, font_name=FONT, icon_size='18sp', **k)

        self.date_lbl = ml('', '13sp', theme_text_color='Hint', size_hint_x=0.17)
        self.cat_lbl = ml('', '15sp', theme_text_color='Primary', size_hint_x=0.16)
        self.desc_lbl = ml('', '14sp', theme_text_color='Hint', size_hint_x=0.32, halign='left')
        self.amt_lbl = ml('', '16sp', bold=True, size_hint_x=0.25, halign='right')
        self.del_btn = ib('close', theme_text_color='Custom', text_color=(0.7,0.7,0.7,1),
                          size_hint_x=None, width=dp(40), opacity=0, disabled=True)

        for w in (self.date_lbl, self.cat_lbl, self.desc_lbl, self.amt_lbl, self.del_btn):
            self.add_widget(w)


class AccountBookApp(MDApp):
    def build(self):
        self.theme_cls.primary_palette = 'Green'
        db.init_db()

        nav = MDBottomNavigation()

        # ---------- Dashboard tab ----------
        dash = MDBottomNavigationItem(name='dashboard', text='首页', icon='home')
        dash_box = BoxLayout(orientation='vertical')
        dash_bar = MDTopAppBar(title='我的账本', md_bg_color=GREEN, specific_text_color='ffffff')
        dash_box.add_widget(dash_bar)

        dash_scroll = ScrollView()
        dash_content = BoxLayout(orientation='vertical', size_hint_y=None,
                                 padding=[dp(16)], spacing=dp(16))
        dash_content.bind(minimum_height=dash_content.setter('height'))
        dash_scroll.add_widget(dash_content)
        dash_box.add_widget(dash_scroll)
        dash.add_widget(dash_box)

        # Balance card
        bal_card = MDCard(orientation='vertical', size_hint_y=None, height=dp(190),
                          padding=[dp(20), dp(16)], spacing=dp(6), radius=dp(12))
        bal_card.add_widget(MDLabel(text='当前余额', font_name=FONT, font_size='14sp',
                                    theme_text_color='Hint', size_hint_y=None, height=dp(22)))
        self.balance_lbl = MDLabel(text='¥0.00', font_name=FONT, font_size='38sp', bold=True,
                                    theme_text_color='Primary', size_hint_y=None, height=dp(56))
        bal_card.add_widget(self.balance_lbl)
        bal_card.add_widget(Widget(size_hint_y=None, height=dp(8)))

        inc_box = BoxLayout(size_hint_y=None, height=dp(40), spacing=dp(12))
        def mk_row(lbl_text, lbl_id, color):
            b = BoxLayout()
            b.add_widget(MDLabel(text=lbl_text, font_name=FONT, font_size='13sp',
                                 theme_text_color='Hint', size_hint_x=0.22))
            lbl = MDLabel(text='¥0', font_name=FONT, font_size='17sp', bold=True,
                          theme_text_color='Custom', text_color=color)
            b.add_widget(lbl)
            return b, lbl
        self.income_lbl = mk_row('收入', 'income', GREEN_LT)[1]
        self.expense_lbl = mk_row('支出', 'expense', RED)[1]
        inc_box.add_widget(mk_row('收入', 'income', GREEN_LT)[0])
        inc_box.add_widget(mk_row('支出', 'expense', RED)[0])
        bal_card.add_widget(inc_box)
        dash_content.add_widget(bal_card)

        # Recent card
        recent_card = MDCard(orientation='vertical', size_hint_y=None,
                             padding=[dp(16), dp(10)], spacing=dp(4), radius=dp(12))
        recent_card.bind(minimum_height=recent_card.setter('height'))
        hdr = BoxLayout(size_hint_y=None, height=dp(38))
        hdr.add_widget(MDLabel(text='最近记录', font_name=FONT, font_size='17sp', bold=True,
                                theme_text_color='Primary'))
        view_all = MDFlatButton(text='全部', font_name=FONT, font_size='14sp',
                                 text_color=GREEN, on_release=lambda x: self._switch_to('list'))
        hdr.add_widget(view_all)
        recent_card.add_widget(hdr)

        self.recent_scroll = ScrollView(size_hint_y=None, height=dp(240), do_scroll_x=False)
        self.recent_container = BoxLayout(orientation='vertical', size_hint_y=None)
        self.recent_container.bind(minimum_height=self.recent_container.setter('height'))
        self.recent_scroll.add_widget(self.recent_container)
        recent_card.add_widget(self.recent_scroll)

        add_btn = MDRaisedButton(text='记一笔', font_name=FONT, font_size='17sp',
                                 md_bg_color=GREEN_LT, size_hint_y=None, height=dp(48),
                                 on_release=lambda x: self._switch_to('add'))
        recent_card.add_widget(add_btn)
        dash_content.add_widget(recent_card)
        nav.add_widget(dash)

        # ---------- Add tab ----------
        add = MDBottomNavigationItem(name='add', text='记账', icon='plus')
        self.add_box = BoxLayout(orientation='vertical')
        add_bar = MDTopAppBar(title='新增记录', md_bg_color=GREEN, specific_text_color='ffffff')
        self.add_box.add_widget(add_bar)

        add_scroll = ScrollView()
        add_form = BoxLayout(orientation='vertical', size_hint_y=None,
                             padding=[dp(16)], spacing=dp(16))
        add_form.bind(minimum_height=add_form.setter('height'))
        add_scroll.add_widget(add_form)
        self.add_box.add_widget(add_scroll)
        add.add_widget(self.add_box)
        add.bind(on_tab_press=lambda x: self._refresh_add())

        # Amount field
        def field(hint, icon_l, **kw):
            return MDTextField(hint_text=hint, font_name=FONT, icon_left=icon_l,
                               size_hint_y=None, height=dp(56), **kw)
        add_form.add_widget(field('金额', 'currency-cny'))
        self.amount_input = add_form.children[0]

        # Type toggle
        type_box = BoxLayout(size_hint_y=None, height=dp(44), spacing=dp(12))
        def tb(txt):
            return ToggleButton(text=txt, font_name=FONT, font_size='16sp',
                                group='tx_type', background_normal='',
                                background_color=(0.92,0.92,0.92,1), color=(0.35,0.35,0.35,1))
        self.income_toggle = tb('收入')
        self.expense_toggle = tb('支出')
        self.expense_toggle.state = 'down'
        self.income_toggle.bind(on_release=lambda x: self._build_categories('income'))
        self.expense_toggle.bind(on_release=lambda x: self._build_categories('expense'))
        type_box.add_widget(self.income_toggle)
        type_box.add_widget(self.expense_toggle)
        add_form.add_widget(type_box)

        # Categories
        add_form.add_widget(MDLabel(text='分类', font_name=FONT, font_size='15sp',
                                     theme_text_color='Hint', size_hint_y=None, height=dp(22)))
        self.cat_grid = GridLayout(cols=4, spacing=dp(8), size_hint_y=None)
        self.cat_grid.bind(minimum_height=self.cat_grid.setter('height'))
        add_form.add_widget(self.cat_grid)

        # Date / Description
        add_form.add_widget(field('日期', 'calendar'))
        self.date_input = add_form.children[0]
        add_form.add_widget(field('备注（可选）', 'pencil'))
        self.desc_input = add_form.children[0]

        # Save
        self.save_btn = MDRaisedButton(text='保存', font_name=FONT, font_size='19sp',
                                        md_bg_color=GREEN_LT, size_hint_y=None, height=dp(56),
                                        on_release=lambda x: self._save_tx())
        add_form.add_widget(self.save_btn)

        nav.add_widget(add)

        # ---------- List tab ----------
        lst = MDBottomNavigationItem(name='list', text='账单', icon='format-list-bulleted')
        lst_box = BoxLayout(orientation='vertical')
        lst_bar = MDTopAppBar(title='全部记录', md_bg_color=GREEN, specific_text_color='ffffff')
        lst_box.add_widget(lst_bar)

        # Month selector
        month_box = BoxLayout(size_hint_y=None, height=dp(48), padding=[dp(16), 0], spacing=dp(10))
        self.month_lbl = MDLabel(text='2026年07月', font_name=FONT, font_size='17sp',
                                  bold=True, theme_text_color='Primary')
        prev_btn = MDIconButton(icon='chevron-left', icon_size='22sp',
                                 theme_text_color='Custom', text_color=(0.3,0.3,0.3,1),
                                 on_release=lambda x: self._prev_month())
        next_btn = MDIconButton(icon='chevron-right', icon_size='22sp',
                                 theme_text_color='Custom', text_color=(0.3,0.3,0.3,1),
                                 on_release=lambda x: self._next_month())
        month_box.add_widget(prev_btn)
        month_box.add_widget(self.month_lbl)
        month_box.add_widget(next_btn)
        lst_box.add_widget(month_box)

        lst_scroll = ScrollView(do_scroll_x=False)
        self.list_container = BoxLayout(orientation='vertical', size_hint_y=None, spacing=1)
        self.list_container.bind(minimum_height=self.list_container.setter('height'))
        lst_scroll.add_widget(self.list_container)
        lst_box.add_widget(lst_scroll)
        lst.add_widget(lst_box)
        nav.add_widget(lst)

        self.cats_loaded = 'expense'
        self.cur_year = date.today().year
        self.cur_month = date.today().month
        self.edit_id = 0

        # Initial build
        Clock.schedule_once(lambda dt: self._refresh_dash(), 0)
        Clock.schedule_once(lambda dt: self._build_categories('expense'), 0)
        Clock.schedule_once(self._fix_all_fonts, 0.3)

        return nav

    # ----- helpers -----
    def _fix_all_fonts(self, dt):
        for widget in self.root.walk():
            if hasattr(widget, 'font_name'):
                try:
                    widget.font_name = FONT
                except:
                    pass
        for widget in self.root.walk():
            if hasattr(widget, 'hint_text') and hasattr(widget, '_hint_lbl'):
                try:
                    widget._hint_lbl.font_name = FONT
                except:
                    pass

    def _refresh_add(self):
        self.amount_input.text = ''
        self.desc_input.text = ''
        self.date_input.text = date.today().strftime('%Y-%m-%d')
        self.income_toggle.state = 'normal'
        self.expense_toggle.state = 'down'
        self.save_btn.text = '保存'
        self.edit_id = 0
        self._build_categories('expense')

    def _switch_to(self, name):
        self.root.switch_tab(name)
        if name == 'list':
            self._refresh_list()
        elif name == 'dashboard':
            self._refresh_dash()
        elif name == 'add':
            self._refresh_add()

    def _refresh_dash(self):
        now = date.today()
        total = db.get_summary()
        monthly = db.get_monthly_summary(now.year, now.month)
        self.balance_lbl.text = f'¥{total["balance"]:.2f}'
        self.income_lbl.text = f'¥{monthly["total_income"]:.0f}'
        self.expense_lbl.text = f'¥{monthly["total_expense"]:.0f}'

        self.recent_container.clear_widgets()
        for r in db.get_transactions(5):
            item = TxItem(tx_id=r['id'])
            item.del_btn.opacity = 0
            item.date_lbl.text = r['date']
            item.cat_lbl.text = r['category_name']
            item.desc_lbl.text = r['description'] or ''
            s = '+' if r['type']=='income' else '-'
            c = GREEN_LT if r['type']=='income' else RED
            item.amt_lbl.text = f'{s}¥{r["amount"]:.1f}'
            item.amt_lbl.text_color = c
            item.amt_lbl.theme_text_color = 'Custom'
            self.recent_container.add_widget(item)

    def _build_categories(self, t_type):
        self.cat_grid.clear_widgets()
        cats = db.get_categories(t_type)
        for idx, cat in enumerate(cats):
            btn = ToggleButton(text=cat['name'], font_name=FONT, group='cat',
                               background_normal='', background_color=(0.95,0.95,0.95,1),
                               color=(0.25,0.25,0.25,1), font_size='15sp',
                               size_hint_y=None, height=dp(42))
            btn.cat_id = cat['id']
            if idx == 0: btn.state = 'down'
            self.cat_grid.add_widget(btn)

    def _selected_cat_id(self):
        for btn in self.cat_grid.children:
            if btn.state == 'down' and hasattr(btn, 'cat_id'):
                return btn.cat_id
        return None

    def _save_tx(self):
        txt = self.amount_input.text.strip()
        if not txt:
            Snackbar(text='请输入金额', bg_color=GREEN).open(); return
        try:
            amt = float(txt)
            if amt <= 0:
                Snackbar(text='金额须大于0', bg_color=GREEN).open(); return
        except:
            Snackbar(text='金额格式错误', bg_color=GREEN).open(); return

        d = self.date_input.text.strip() or date.today().strftime('%Y-%m-%d')
        desc = self.desc_input.text.strip()
        typ = 'income' if self.income_toggle.state == 'down' else 'expense'
        cat_id = self._selected_cat_id()

        if self.edit_id:
            db.update_transaction(self.edit_id, typ, amt, cat_id, d, desc)
            self.edit_id = 0
        else:
            db.add_transaction(typ, amt, cat_id, d, desc)
        Snackbar(text='保存成功', bg_color=GREEN).open()
        self._switch_to('dashboard')
        Clock.schedule_once(lambda dt: self._refresh_list(), 0.3)

    def _prev_month(self):
        self.cur_month -= 1
        if self.cur_month < 1: self.cur_month = 12; self.cur_year -= 1
        self._refresh_list()

    def _next_month(self):
        self.cur_month += 1
        if self.cur_month > 12: self.cur_month = 1; self.cur_year += 1
        self._refresh_list()

    def _refresh_list(self):
        self.month_lbl.text = f'{self.cur_year}年{self.cur_month:02d}月'
        self.list_container.clear_widgets()
        rows = db.get_transactions_by_month(self.cur_year, self.cur_month, 200)
        if not rows:
            self.list_container.add_widget(MDLabel(
                text='本月暂无记录', font_name=FONT, font_size='16sp',
                theme_text_color='Hint', size_hint_y=None, height=dp(100)))
            return
        for r in rows:
            item = TxItem(tx_id=r['id'])
            item.del_btn.disabled = False
            item.del_btn.opacity = 1
            item.del_btn.bind(on_release=lambda btn, tid=r['id']: self._confirm_delete(tid))
            item.date_lbl.text = r['date']
            item.cat_lbl.text = r['category_name']
            item.desc_lbl.text = r['description'] or ''
            s = '+' if r['type']=='income' else '-'
            c = GREEN_LT if r['type']=='income' else RED
            item.amt_lbl.text = f'{s}¥{r["amount"]:.1f}'
            item.amt_lbl.text_color = c
            item.amt_lbl.theme_text_color = 'Custom'
            self.list_container.add_widget(item)

        summary = db.get_monthly_summary(self.cur_year, self.cur_month)
        bar = BoxLayout(size_hint_y=None, height=dp(44), padding=[dp(16), 0])
        bar.add_widget(MDLabel(text=f'收入 ¥{summary["total_income"]:.0f}', font_name=FONT,
                                font_size='14sp', bold=True, theme_text_color='Custom',
                                text_color=GREEN_LT))
        bar.add_widget(MDLabel(text=f'支出 ¥{summary["total_expense"]:.0f}', font_name=FONT,
                                font_size='14sp', bold=True, theme_text_color='Custom',
                                text_color=RED))
        bar.add_widget(MDLabel(text=f'结余 ¥{summary["balance"]:.0f}', font_name=FONT,
                                font_size='14sp', bold=True, theme_text_color='Primary'))
        self.list_container.add_widget(bar)

    def _confirm_delete(self, tx_id):
        self._delete_target = tx_id
        self._del_dialog = MDDialog(
            title='删除记录',
            text='确定要删除这条记录吗？',
            buttons=[
                MDFlatButton(text='取消', on_release=lambda x: self._del_dialog.dismiss()),
                MDFlatButton(text='删除', text_color=RED,
                             on_release=lambda x: self._do_delete()),
            ],
        )
        self._del_dialog.open()

    def _do_delete(self):
        db.delete_transaction(self._delete_target)
        if hasattr(self, '_del_dialog'):
            self._del_dialog.dismiss()
        Snackbar(text='已删除', bg_color=GREEN).open()
        self._refresh_list()


if __name__ == '__main__':
    AccountBookApp().run()
