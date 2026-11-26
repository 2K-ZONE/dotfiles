set modeline
set autoindent          " copy indent from current line when starting a new line
set smartindent         " even better autoindent (e.g. add indent after '{')
set scrolloff=20
set bg=dark
set cursorline
set nofixeol
set nofixendofline
set noeol
set noexpandtab
set tabstop=8
set shiftwidth=8
set softtabstop=0

syntax enable
filetype plugin indent on

" Return to last edit position when opening files (You want this!)
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif

"""" Search settings
set incsearch           " search as characters are entered
set hlsearch            " highlight matches

" turn off search highlighting with <CR> (carriage-return)
nnoremap <CR> :nohlsearch<CR><CR>

let g:gruvbox_transparent_bg = '1'
let g:gruvbox_contrast_dark= 'hard'
let g:onedark_terminal_italics = 1
let g:airline_powerline_fonts = 1
let g:airline_theme = 'gruvbox'

autocmd vimenter * ++nested colorscheme gruvbox

" Transparent background
autocmd vimenter * hi Normal guibg=NONE ctermbg=NONE

autocmd FileType c setlocal noexpandtab tabstop=8 shiftwidth=8 softtabstop=0

