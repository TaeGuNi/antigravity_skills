// [💡 Core Ref Injector (Playwright Context - Ultimate ROI & Performance)]
const generateRefMap = () => {
  const interactableSelectors = 'a[href], button, input, textarea, select, iframe, [role="button"], [role="link"], [tabindex]:not([tabindex="-1"])';
  const elements = new Set();

  // 1. 재귀적 DOM 순회 함수 (Shadow DOM 투과)
  const traverse = (node) => {
    if (!node) return;
    if (node.nodeType === 1 && node.matches && node.matches(interactableSelectors)) elements.add(node);
    if (node.shadowRoot) traverse(node.shadowRoot);
    for (const child of node.childNodes) traverse(child);
  };

  traverse(document);

  let refCounter = 0;
  const refMap = [];
  const viewportHeight = window.innerHeight;
  const viewportWidth = window.innerWidth;
  
  // 🚨 토큰 다이어트 한계: 무의미한 수백개 요소 수집 차단
  const MAX_ELEMENTS = 150; 

  // 배열로 변환하여 화면(가시성) 우선순위로 약간의 랭킹 부여 가능 (여기는 기본 순회)
  const elArray = Array.from(elements);

  for (let i = 0; i < elArray.length; i++) {
    if (refCounter >= MAX_ELEMENTS) {
       refMap.push(`\n... [Warning: Max Limits Hit (${MAX_ELEMENTS}). Omitted trailing nodes. Please Scope Down your search.]`);
       break;
    }
    const el = elArray[i];

    // 2. 가시성 1차 초고속 필터링 (Layout Thrashing 방지)
    const style = window.getComputedStyle(el);
    if (style.display === 'none' || style.visibility === 'hidden' || style.opacity === '0') continue;

    // 3. 2차 정밀 스크린 판별
    const rect = el.getBoundingClientRect();
    if (rect.width === 0 || rect.height === 0 || rect.x < -9999) continue;
    
    // [힌트 1] 스크롤 밖 (Off-Screen) 판단
    const isOffScreen = (rect.y > viewportHeight || rect.x > viewportWidth) ? '[OffScreen] ' : '';

    // [힌트 2] 요소가 다른 모달/오버레이에 가려져 있는지 (Obscured) Z-Index 장애물 판별
    let isObscured = '';
    if (!isOffScreen) {
      const centerX = rect.x + rect.width / 2;
      const centerY = rect.y + rect.height / 2;
      const topEl = document.elementFromPoint(centerX, centerY);
      if (topEl && topEl !== el && !el.contains(topEl)) {
         isObscured = '[Obscured] ';
      }
    }

    // 4. 고유 Ref ID 부여
    const refId = `@e${refCounter++}`;
    el.setAttribute('data-agent-ref', refId);

    const tagName = el.tagName.toLowerCase();

    // 5. iFrame(Cross-Origin) 인지 힌트
    if (tagName === 'iframe') {
      const src = el.getAttribute('src') || 'unknown';
      refMap.push(`[${refId}] ${isOffScreen}${isObscured}iframe[src="${src}"] "External Frame (Requires Context Switch)"`);
      continue;
    }

    // 6. 노이즈 없는 라벨(Label) 및 [힌트 3] 아이콘 버튼 텍스트 추론
    let rawLabel = el.textContent || el.getAttribute('aria-label') || el.getAttribute('placeholder') || el.getAttribute('name') || '';
    let label = rawLabel.replace(/\s+/g, ' ').trim();
    
    if (!label) {
       const clue = el.id || el.className || 'IconOnly';
       label = `[NoText: ${clue.substring(0, 15)}]`;
    } else if (label.length > 50) {
       label = label.substring(0, 47) + '...';
    }

    // 7. 타입 속성 부착 시그니처 조립
    const typeAttr = el.hasAttribute('type') ? `[type="${el.getAttribute('type')}"]` : '';
    
    refMap.push(`[${refId}] ${tagName}${typeAttr} ${isOffScreen}${isObscured}"${label}"`);
  }

  return refMap.join('\n');
};
