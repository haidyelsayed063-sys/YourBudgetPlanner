//
//  localization.swift
//  manageyourexpense
//
//  Created by IFTS42 on 30/10/2026.
//

//
//  localization.swift
//  manageyourexpense
//
//  Created by IFTS42 on 30/10/2026.
//

//
//  localization.swift
//  manageyourexpense
//
//  Created by IFTS42 on 30/10/2026.
//

import UIKit

enum AppLanguage: String, CaseIterable {
    case en, ar, fr, it, zh

    var nativeName: String {
        switch self {
        case .en: return "English"
        case .ar: return "العربية"
        case .fr: return "Français"
        case .it: return "Italiano"
        case .zh: return "中文"
        }
    }

    /// Locale for month names and dates. Arabic keeps Western digits (0-9) like the amounts.
    var locale: Locale {
        switch self {
        case .en: return Locale(identifier: "en_US")
        case .ar: return Locale(identifier: "ar-u-nu-latn")
        case .fr: return Locale(identifier: "fr_FR")
        case .it: return Locale(identifier: "it_IT")
        case .zh: return Locale(identifier: "zh_CN")
        }
    }

    static var current: AppLanguage {
        get { AppLanguage(rawValue: UserDefaults.standard.string(forKey: "appLanguage") ?? "") ?? .en }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "appLanguage") }
    }
}

extension String {
    var tr: String {
        let lang = AppLanguage.current
        guard lang != .en, let row = L10n.table[self] else { return self }
        let index: Int
        switch lang {
        case .ar: index = 0
        case .fr: index = 1
        case .it: index = 2
        case .zh: index = 3
        case .en: return self
        }
        return row[index]
    }
}

enum LanguageManager {
    /// Arabic = right-to-left, every other language = left-to-right.
    static func applyDirection() {
        let attribute: UISemanticContentAttribute = AppLanguage.current == .ar ? .forceRightToLeft : .forceLeftToRight
        UIView.appearance().semanticContentAttribute = attribute
        UITabBar.appearance().semanticContentAttribute = attribute
    }

    static func reloadUI() {
        applyDirection()
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.windows.first }).first else { return }
        window.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
    }
}

enum L10n {
    static let table: [String: [String]] = [
        // Tabs
        "Home": ["الرئيسية", "Accueil", "Home", "首页"],
        "Plan": ["الخطة", "Plan", "Piano", "计划"],
        "Activity": ["النشاط", "Activité", "Attività", "活动"],
        "Goals": ["الأهداف", "Objectifs", "Obiettivi", "目标"],
        
        // Categories
        "Housing": ["السكن", "Logement", "Alloggio", "住房"],
        "Food": ["الطعام", "Nourriture", "Cibo", "食物"],
        "Dining": ["المطاعم", "Restaurants", "Ristoranti", "餐饮"],
        "Transport": ["المواصلات", "Transport", "Trasporti", "交通"],
        "Utilities & internet": ["الخدمات والإنترنت", "Services et Internet", "Utenze e internet", "公用事业与网络"],
        "Subscriptions": ["الاشتراكات", "Abonnements", "Abbonamenti", "订阅"],
        "Shopping": ["التسوق", "Shopping", "Shopping", "购物"],
        "Other": ["أخرى", "Autre", "Altro", "其他"],

        // Activity
        "All transactions": ["جميع المعاملات", "Toutes les transactions", "Tutte le transazioni", "所有交易"],
        "Exactly where it went": ["أين ذهبت الأموال بالتحديد", "Exactement où c'est parti", "Esattamente dove è andato", "钱究竟花在哪里"],
        "Today": ["اليوم", "Aujourd'hui", "Oggi", "今天"],
        "Earlier this month": ["أول الشهر", "Plus tôt ce mois-ci", "Prima, questo mese", "本月早些时候"],
        "Older": ["أقدم", "Plus ancien", "Più vecchi", "更早"],
        "All": ["الكل", "Tout", "Tutti", "全部"],
        "Expenses": ["المصروفات", "Dépenses", "Spese", "支出"],
        "Income": ["الدخل", "Revenus", "Entrate", "收入"],
        "Recurring": ["المتكررة", "Récurrents", "Ricorrenti", "定期"],
        "Still available": ["المبلغ المتاح", "Encore disponible", "Ancora disponibile", "仍可用"],
        "This month so far": ["حتى الآن هذا الشهر", "Ce mois-ci jusqu'ici", "Questo mese finora", "本月至今"],
        "Nothing here yet. Tap the + button to add a transaction.":
            ["لا توجد معاملات هنا بعد. اضغط على زر + لإضافة معاملة.", "Rien pour l'instant. Appuyez sur + pour ajouter une transaction.", "Ancora niente. Tocca + per aggiungere una transazione.", "暂无内容。点按 + 添加交易。"],
        
        // Home & Dynamic Labels (Fusha)
        "Left this month": ["المتبقي هذا الشهر", "Reste ce mois-ci", "Rimasto questo mese", "本月剩余"],
        "Smart move": ["خطوة ذكية", "Bon réflexe", "Mossa intelligente", "明智之举"],
        "This month": ["هذا الشهر", "Ce mois-ci", "Questo mese", "本月"],
        "Where it went": ["أين ذهبت الأموال", "Où c'est parti", "Dove è andato", "花在哪里"],
        "View plan": ["عرض الخطة", "Voir le plan", "Vedi piano", "查看计划"],
        "Recent": ["الأخيرة", "Récent", "Recenti", "最近"],
        "Latest activity": ["النشاط الأخير", "Dernière activité", "Ultima attività", "最新活动"],
        "See all": ["عرض الكل", "Tout voir", "Vedi tutto", "查看全部"],
        "used": ["مستخدم", "utilisé", "usato", "已用"],
        "Set your monthly salary": ["حدد راتبك الشهري", "Définissez votre salaire mensuel", "Imposta il tuo stipendio mensile", "设置月薪"],
        "Add it in the Plan tab and we will build your plan.":
            ["أضفه في تبويب الخطة وسنقوم بإنشاء خطتك.", "Ajoutez-le dans l'onglet Plan et nous créerons votre plan.", "Aggiungilo nella scheda Piano e creeremo il tuo piano.", "在“计划”页添加,我们会为你制定计划。"],
        "No transactions yet. Tap the + button to add your first expense.":
            ["لا توجد معاملات بعد. اضغط على زر + لإضافة مصروفك الأول.", "Aucune transaction. Appuyez sur + pour ajouter votre première dépense.", "Nessuna transazione. Tocca + per aggiungere la prima spesa.", "暂无交易。点按 + 添加第一笔支出。"],
        
        // Dynamic formats for Home
        "%d days left": ["متبقٍ %d يوم", "%d jours restants", "%d giorni rimasti", "剩余 %d 天"],
        "After savings, spend up to %@ per day": ["بعد الادخار، يمكنك إنفاق ما يصل إلى %@ في اليوم", "Après l'épargne, dépensez jusqu'à %@ par jour", "Dopo i risparmi, spendi fino a %@ al giorno", "储蓄后，每天最多花 %@"],
        "%@ spent": ["تم إنفاق %@", "%@ dépensés", "%@ spesi", "已花 %@"],
        "%@ salary": ["الراتب %@", "%@ salaire", "%@ stipendio", "薪资 %@"],
        "Set aside %@ for emergencies": ["تخصيص %@ للطوارئ", "Mettez de côté %@ pour les urgences", "Metti da parte %@ per le emergenze", "留出 %@ 作为应急资金"],
        "That's %d%% of your salary, before extra spending.": ["هذه نسبة %d%% من راتبك، قبل أي مصاريف إضافية.", "C'est %d%% de votre salaire, avant les dépenses extra.", "Questo è il %d%% del tuo stipendio, prima delle spese extra.", "这占你薪资的 %d%%，在额外支出之前。"],

        // Currencies nouns
        "euro": ["يورو", "euro", "euro", "欧元"],
        "dollar": ["دولار", "dollar", "dollaro", "美元"],
        "pound": ["جنيه إسترليني", "livre", "sterlina", "英镑"],

        // Add expense
        "New transaction": ["معاملة جديدة", "Nouvelle transaction", "Nuova transazione", "新交易"],
        "Add an expense": ["إضافة مصروف", "Ajouter une dépense", "Aggiungi una spesa", "添加支出"],
        "Add income": ["إضافة دخل", "Ajouter un revenu", "Aggiungi un'entrata", "添加收入"],
        "Amount": ["المبلغ", "Montant", "Importo", "金额"],
        "Description": ["الوصف", "Description", "Descrizione", "说明"],
        "Category": ["الفئة", "Catégorie", "Categoria", "类别"],
        "Save": ["حفظ", "Enregistrer", "Salva", "保存"],
        
        // Onboarding
        "Welcome to MoneyFlow": ["مرحباً بك في MoneyFlow", "Bienvenue sur MoneyFlow", "Benvenuto in MoneyFlow", "欢迎使用 MoneyFlow"],
        "Your plan": ["خطتك", "Votre plan", "Il tuo piano", "你的计划"],
        "Update your plan": ["تحديث خطتك", "Mettre à jour votre plan", "Aggiorna il tuo piano", "更新你的计划"],
        "Let's set up your salary plan": ["لنقم بإعداد خطة راتبك", "Configurons votre plan salaire", "Impostiamo il tuo piano stipendio", "来设置你的薪资计划"],
        "Tell us what you earn. We split it for you: bills first, then savings, then what is safe to spend.":
            ["أخبرنا بما تكتسبه. سنقوم بتقسيمه لك: الفواتير أولاً، ثم المدخرات، وما يبقى هو ما يمكنك إنفاقه بأمان.", "Dites-nous ce que vous gagnez. Nous le répartissons : factures d'abord, puis épargne, puis ce que vous pouvez dépenser.", "Dicci quanto guadagni. Lo dividiamo noi: prima le bollette, poi i risparmi, poi ciò che puoi spendere.", "告诉我们你的收入。我们帮你分配:先付账单,再储蓄,剩下的可以放心花。"],
        "Monthly salary": ["الراتب الشهري", "Salaire mensuel", "Stipendio mensile", "月薪"],
        "Payday (day of the month)": ["يوم استلام الراتب (من الشهر)", "Jour de paie (du mois)", "Giorno di paga (del mese)", "发薪日(每月几号)"],
        "Currency": ["العملة", "Devise", "Valuta", "货币"],
        "Language": ["اللغة", "Langue", "Lingua", "语言"],
        "Emergency fund (% of salary)": ["صندوق الطوارئ (نسبة مئوية من الراتب)", "Fonds d'urgence (% du salaire)", "Fondo emergenze (% dello stipendio)", "应急基金(占薪资 %)"],
        "Savings (% of salary)": ["المدخرات (نسبة مئوية من الراتب)", "Épargne (% du salaire)", "Risparmi (% dello stipendio)", "储蓄(占薪资 %)"],
        "Continue": ["متابعة", "Continuer", "Continua", "继续"],
        "Save changes": ["حفظ التغييرات", "Enregistrer", "Salva modifiche", "保存更改"],
        
        // Plan
        "Plan before you spend": ["خطط قبل أن تنفق", "Planifiez avant de dépenser", "Pianifica prima di spendere", "先计划再花钱"],
        "Tap here to set your monthly salary": ["اضغط هنا لتحديد راتبك الشهري", "Touchez ici pour définir votre salaire", "Tocca qui per impostare lo stipendio", "点按此处设置月薪"],
        "fixed bills": ["فواتير ثابتة", "factures fixes", "bollette fisse", "固定账单"],
        "save first": ["الادخار أولاً", "épargner d'abord", "risparmia prima", "先储蓄"],
        "Emergency": ["الطوارئ", "Urgence", "Emergenze", "应急"],
        "Savings": ["المدخرات", "Épargne", "Risparmi", "储蓄"],
        "Flexible": ["مرن", "Flexible", "Flessibile", "灵活"],
        "Repeats every month": ["يتكرر كل شهر", "Se répète chaque mois", "Si ripete ogni mese", "每月重复"],
        "Your fixed expenses": ["مصروفاتك الثابتة", "Vos dépenses fixes", "Le tue spese fisse", "你的固定支出"],
        "+ Add bill": ["+ إضافة فاتورة", "+ Ajouter une facture", "+ Aggiungi bolletta", "+ 添加账单"],
        "Your simple payday order": ["ترتيب يوم الراتب البسيط", "Votre ordre simple le jour de paie", "Il tuo semplice ordine di paga", "你的发薪日顺序"],
        
        // Goals
        "Your safety net": ["شبكة الأمان الخاص بك", "Votre filet de sécurité", "La tua rete di sicurezza", "你的安全网"],
        "Save with a purpose": ["وفر لهدف معين", "Épargnez avec un but", "Risparmia con uno scopo", "有目标地储蓄"],
        "Top priority": ["أولوية قصوى", "Priorité absolue", "Massima priorità", "最高优先级"],
        "Next up": ["التالي", "À suivre", "Prossimi", "接下来"],
        "More goals": ["أهداف أخرى", "Plus d'objectifs", "Altri obiettivi", "更多目标"],
        "+ New goal": ["+ هدف جديد", "+ Nouvel objectif", "+ Nuovo obiettivo", "+ 新目标"],

        // ---- Added ----
        "Groceries": ["البقالة", "Courses", "Spesa alimentare", "食品杂货"],
        "Yesterday": ["أمس", "Hier", "Ieri", "昨天"],
        "Expense": ["مصروف", "Dépense", "Spesa", "支出"],
        "Delete": ["حذف", "Supprimer", "Elimina", "删除"],
        "Cancel": ["إلغاء", "Annuler", "Annulla", "取消"],
        "OK": ["موافق", "OK", "OK", "好"],
        "Add": ["إضافة", "Ajouter", "Aggiungi", "添加"],
        "Create": ["إنشاء", "Créer", "Crea", "创建"],
        "SAFE": ["آمن", "SÛR", "SICURO", "安全"],

        // Dynamic (Activity / Home)
        "Spent in %@": ["المصروف في %@", "Dépensé en %@", "Speso in %@", "%@ 已支出"],
        "%@ %d%% vs. %@": ["%@ %d%% مقارنة بـ %@", "%@ %d%% vs %@", "%@ %d%% rispetto a %@", "%@ %d%%，对比%@"],
        "%@ money snapshot": ["ملخص أموالك لشهر %@", "Aperçu financier de %@", "Panoramica di %@", "%@ 财务概览"],
        "Know where every %@ goes.": ["اعرف إلى أين يذهب كل %@.", "Sachez où va chaque %@.", "Sai dove va ogni %@.", "清楚每一%@的去向。"],

        // Currency names
        "Egyptian pound": ["جنيه مصري", "livre égyptienne", "sterlina egiziana", "埃及镑"],
        "riyal": ["ريال", "riyal", "riyal", "里亚尔"],
        "dirham": ["درهم", "dirham", "dirham", "迪拉姆"],
        "franc": ["فرنك", "franc", "franco", "法郎"],
        "yuan": ["يوان", "yuan", "yuan", "元"],
        "yen": ["ين", "yen", "yen", "日元"],

        // Add expense
        "What did you spend on?": ["على ماذا أنفقت؟", "Pour quoi avez-vous dépensé ?", "Per cosa hai speso?", "花在什么上？"],
        "Where did it come from?": ["من أين جاء؟", "D'où cela vient-il ?", "Da dove viene?", "来自哪里？"],
        "Check the amount": ["تحقق من المبلغ", "Vérifiez le montant", "Controlla l'importo", "请检查金额"],
        "Enter an amount greater than zero.": ["أدخل مبلغاً أكبر من الصفر.", "Saisissez un montant supérieur à zéro.", "Inserisci un importo maggiore di zero.", "请输入大于零的金额。"],

        // Onboarding errors
        "Check your details": ["تحقق من بياناتك", "Vérifiez vos informations", "Controlla i tuoi dati", "请检查你的信息"],
        "Enter your monthly salary.": ["أدخل راتبك الشهري.", "Saisissez votre salaire mensuel.", "Inserisci il tuo stipendio mensile.", "请输入你的月薪。"],
        "Payday must be a day between 1 and 31.": ["يجب أن يكون يوم الراتب بين 1 و 31.", "Le jour de paie doit être entre 1 et 31.", "Il giorno di paga deve essere tra 1 e 31.", "发薪日必须在 1 到 31 之间。"],
        "Emergency and savings percentages must be numbers, and together not more than 100.":
            ["يجب أن تكون نسبتا الطوارئ والمدخرات أرقاماً ومجموعهما لا يتجاوز 100.", "Les pourcentages d'urgence et d'épargne doivent être des nombres, et au total pas plus de 100.", "Le percentuali di emergenza e risparmio devono essere numeri e insieme non superare 100.", "应急和储蓄比例必须是数字，且总和不超过 100。"],

        // Plan
        "Due on the %@ · %@": ["يستحق في %@ · %@", "Échéance le %@ · %@", "Scade il %@ · %@", "每月 %@ 日到期 · %@"],
        "Estimated": ["تقديري", "Estimé", "Stimato", "预估"],
        "Fixed": ["ثابت", "Fixe", "Fisso", "固定"],
        "%@ every month": ["%@ كل شهر", "%@ chaque mois", "%@ ogni mese", "每月 %@"],
        "First bills, then %@ emergency money, then %@ savings. What remains is safe for daily life.":
            ["الفواتير أولاً، ثم %@ للطوارئ، ثم %@ للمدخرات. وما يتبقى آمن لحياتك اليومية.", "D'abord les factures, puis %@ d'urgence, puis %@ d'épargne. Le reste est pour le quotidien.", "Prima le bollette, poi %@ per le emergenze, poi %@ di risparmi. Il resto è per la vita quotidiana.", "先付账单，再留 %@ 应急，再存 %@。剩下的可放心用于日常生活。"],
        "No fixed bills yet. Add your rent, utilities and subscriptions so we can plan around them.":
            ["لا توجد فواتير ثابتة بعد. أضف الإيجار والخدمات والاشتراكات لنخطط على أساسها.", "Aucune facture fixe. Ajoutez loyer, charges et abonnements pour que nous planifiions autour.", "Nessuna bolletta fissa. Aggiungi affitto, utenze e abbonamenti per pianificare di conseguenza.", "暂无固定账单。添加房租、水电和订阅，我们据此做计划。"],
        "Add a fixed bill": ["إضافة فاتورة ثابتة", "Ajouter une facture fixe", "Aggiungi una bolletta fissa", "添加固定账单"],
        "Something that repeats every month.": ["شيء يتكرر كل شهر.", "Quelque chose qui se répète chaque mois.", "Qualcosa che si ripete ogni mese.", "每月重复的支出。"],
        "Name (e.g. Rent)": ["الاسم (مثلاً الإيجار)", "Nom (ex. Loyer)", "Nome (es. Affitto)", "名称（如房租）"],
        "Due day (1-31)": ["يوم الاستحقاق (1-31)", "Jour d'échéance (1-31)", "Giorno di scadenza (1-31)", "到期日（1-31）"],
        "Please enter a name, an amount and a day between 1 and 31.":
            ["أدخل اسماً ومبلغاً ويوماً بين 1 و 31.", "Saisissez un nom, un montant et un jour entre 1 et 31.", "Inserisci un nome, un importo e un giorno tra 1 e 31.", "请输入名称、金额和 1 到 31 之间的日期。"],
        "Delete bill": ["حذف الفاتورة", "Supprimer la facture", "Elimina bolletta", "删除账单"],

        // Goals
        "No goals yet. Create your first one, for example an emergency fund of 3 months of fixed expenses.":
            ["لا توجد أهداف بعد. أنشئ هدفك الأول، مثلاً صندوق طوارئ بقيمة 3 أشهر من المصروفات الثابتة.", "Aucun objectif. Créez le premier, par exemple un fonds d'urgence de 3 mois de dépenses fixes.", "Nessun obiettivo. Crea il primo, ad esempio un fondo emergenze di 3 mesi di spese fisse.", "暂无目标。创建第一个，例如相当于 3 个月固定支出的应急基金。"],
        "%d%% there": ["تم إنجاز %d%%", "%d%% atteint", "%d%% raggiunto", "已完成 %d%%"],
        " · 3 months of fixed expenses is your target": [" · هدفك 3 أشهر من المصروفات الثابتة", " · votre objectif : 3 mois de dépenses fixes", " · il tuo obiettivo: 3 mesi di spese fisse", " · 目标是 3 个月的固定支出"],
        "of %@": ["من %@", "sur %@", "di %@", "共 %@"],
        "%@ of %@": ["%@ من %@", "%@ sur %@", "%@ di %@", "%@ / %@"],
        "Move %@ here on payday": ["حوّل %@ إلى هنا يوم الراتب", "Transférez %@ ici le jour de paie", "Sposta %@ qui il giorno di paga", "发薪日转入 %@"],
        "At this pace, your safety net will be ready in %@.":
            ["بهذا المعدل ستكون شبكة أمانك جاهزة خلال %@.", "À ce rythme, votre filet de sécurité sera prêt dans %@.", "Di questo passo, la tua rete di sicurezza sarà pronta in %@.", "按此速度，你的安全网将在 %@ 内准备好。"],
        "1 month": ["شهر واحد", "1 mois", "1 mese", "1 个月"],
        "%d months": ["%d أشهر", "%d mois", "%d mesi", "%d 个月"],
        "New goal": ["هدف جديد", "Nouvel objectif", "Nuovo obiettivo", "新目标"],
        "What are you saving for?": ["لماذا تدّخر؟", "Pour quoi épargnez-vous ?", "Per cosa stai risparmiando?", "你为什么而储蓄？"],
        "Name (e.g. Summer trip)": ["الاسم (مثلاً رحلة الصيف)", "Nom (ex. Voyage d'été)", "Nome (es. Viaggio estivo)", "名称（如暑期旅行）"],
        "Target amount": ["المبلغ المستهدف", "Montant cible", "Importo obiettivo", "目标金额"],
        "Already saved (optional)": ["المبلغ المدخر (اختياري)", "Déjà épargné (facultatif)", "Già risparmiato (facoltativo)", "已存金额（可选）"],
        "Please enter a name and a target amount.": ["أدخل اسماً ومبلغاً مستهدفاً.", "Saisissez un nom et un montant cible.", "Inserisci un nome e un importo obiettivo.", "请输入名称和目标金额。"],
        "Add money": ["إضافة مبلغ", "Ajouter de l'argent", "Aggiungi denaro", "添加资金"],
        "Make top priority": ["اجعله أولوية قصوى", "Définir comme priorité", "Rendi prioritario", "设为最高优先级"],
        "Delete goal": ["حذف الهدف", "Supprimer l'objectif", "Elimina obiettivo", "删除目标"],
        "Add to %@": ["إضافة إلى %@", "Ajouter à %@", "Aggiungi a %@", "添加到 %@"],
        "Please enter an amount greater than zero.": ["أدخل مبلغاً أكبر من الصفر.", "Saisissez un montant supérieur à zéro.", "Inserisci un importo maggiore di zero.", "请输入大于零的金额。"]
    ]
}
